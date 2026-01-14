# ContractNest Edge Layer - Complete Fix Specification

> **For Claude Developer**: This document contains the complete specification to fix N+1 queries, add idempotency, and improve observability across the Edge layer.

---

## 📋 Executive Summary

| Problem | Impact | Fix |
|---------|--------|-----|
| `listContacts` makes 3+ DB calls | ~300-500ms latency | Single RPC with embedded data |
| `getContactById` makes 4-5 DB calls | ~400-600ms latency | Single RPC with all relations |
| No idempotency on creates | Duplicates on retry | Idempotency table + check |
| No trace_id | Can't debug across layers | Add to all requests/responses |
| Audit logging awaited | +50-200ms per request | Fire-and-forget |
| No response timing | Can't measure performance | Add duration_ms |

**Target: 1 DB call per request, ~50-100ms latency**

---

## 🗄️ PART 1: DATABASE RPCs (Execute First)

### 1.1 Idempotency Table (Run Once)

```sql
-- Create idempotency tracking table
CREATE TABLE IF NOT EXISTS api_idempotency (
  key UUID PRIMARY KEY,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for cleanup (delete records older than 24h)
CREATE INDEX IF NOT EXISTS idx_api_idempotency_created ON api_idempotency(created_at);

-- Optional: Cleanup function (run daily via pg_cron)
-- DELETE FROM api_idempotency WHERE created_at < NOW() - INTERVAL '24 hours';
```

---

### 1.2 RPC: `list_contacts_with_channels_v2`

**Purpose:** Replace `list_contacts_filtered` with version that includes primary channel and address in ONE query.

```sql
CREATE OR REPLACE FUNCTION list_contacts_with_channels_v2(
  p_tenant_id UUID,
  p_is_live BOOLEAN,
  p_page INTEGER DEFAULT 1,
  p_limit INTEGER DEFAULT 20,
  p_type TEXT DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_search TEXT DEFAULT NULL,
  p_classifications TEXT[] DEFAULT NULL,
  p_user_status TEXT DEFAULT NULL,
  p_show_duplicates BOOLEAN DEFAULT FALSE,
  p_include_inactive BOOLEAN DEFAULT FALSE,
  p_include_archived BOOLEAN DEFAULT FALSE,
  p_sort_by TEXT DEFAULT 'created_at',
  p_sort_order TEXT DEFAULT 'desc'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_offset INTEGER;
  v_total_count INTEGER;
  v_total_pages INTEGER;
  v_status_filter TEXT[];
  v_contacts JSONB;
BEGIN
  -- Calculate offset
  v_offset := (p_page - 1) * p_limit;

  -- Build status filter
  IF p_status IS NOT NULL AND p_status != 'all' THEN
    v_status_filter := ARRAY[p_status];
  ELSIF p_include_inactive AND p_include_archived THEN
    v_status_filter := ARRAY['active', 'inactive', 'archived'];
  ELSIF p_include_inactive THEN
    v_status_filter := ARRAY['active', 'inactive'];
  ELSIF p_include_archived THEN
    v_status_filter := ARRAY['active', 'archived'];
  ELSE
    v_status_filter := ARRAY['active'];
  END IF;

  -- Get total count using CTE for efficiency
  WITH filtered AS (
    SELECT c.id
    FROM t_contacts c
    WHERE c.tenant_id = p_tenant_id
      AND c.is_live = p_is_live
      AND c.status = ANY(v_status_filter)
      AND (p_type IS NULL OR c.type = p_type)
      AND (p_search IS NULL OR c.name ILIKE '%' || p_search || '%' OR c.company_name ILIKE '%' || p_search || '%')
      AND (p_classifications IS NULL OR c.classifications ?| p_classifications)
      AND (p_user_status IS NULL 
           OR (p_user_status = 'user' AND c.auth_user_id IS NOT NULL)
           OR (p_user_status = 'not_user' AND c.auth_user_id IS NULL))
      AND (NOT p_show_duplicates OR c.potential_duplicate = TRUE)
  )
  SELECT COUNT(*) INTO v_total_count FROM filtered;

  v_total_pages := CEIL(v_total_count::FLOAT / p_limit);

  -- Get paginated contacts WITH channels and addresses in ONE query
  SELECT jsonb_agg(contact_data)
  INTO v_contacts
  FROM (
    SELECT jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'company_name', c.company_name,
      'type', c.type,
      'status', c.status,
      'classifications', c.classifications,
      'created_at', c.created_at,
      'updated_at', c.updated_at,
      'parent_contact_ids', c.parent_contact_ids,
      'tenant_id', c.tenant_id,
      'potential_duplicate', c.potential_duplicate,
      'notes', c.notes,
      'salutation', c.salutation,
      'designation', c.designation,
      'department', c.department,
      -- EMBEDDED: Primary channel (no extra query!)
      'primary_channel', (
        SELECT jsonb_build_object(
          'id', ch.id,
          'channel_type', ch.channel_type,
          'value', ch.value,
          'country_code', ch.country_code,
          'is_verified', ch.is_verified
        )
        FROM t_contact_channels ch
        WHERE ch.contact_id = c.id AND ch.is_primary = TRUE
        LIMIT 1
      ),
      -- EMBEDDED: Primary address (no extra query!)
      'primary_address', (
        SELECT jsonb_build_object(
          'id', a.id,
          'type', a.type,
          'city', a.city,
          'state_code', a.state_code,
          'country_code', a.country_code
        )
        FROM t_contact_addresses a
        WHERE a.contact_id = c.id AND a.is_primary = TRUE
        LIMIT 1
      ),
      -- Display name computed in DB
      'displayName', CASE 
        WHEN c.type = 'corporate' THEN COALESCE(c.company_name, 'Unnamed Company')
        ELSE COALESCE(
          CASE WHEN c.salutation IS NOT NULL THEN c.salutation || '. ' ELSE '' END || c.name,
          'Unnamed Contact'
        )
      END
    ) AS contact_data
    FROM t_contacts c
    WHERE c.tenant_id = p_tenant_id
      AND c.is_live = p_is_live
      AND c.status = ANY(v_status_filter)
      AND (p_type IS NULL OR c.type = p_type)
      AND (p_search IS NULL OR c.name ILIKE '%' || p_search || '%' OR c.company_name ILIKE '%' || p_search || '%')
      AND (p_classifications IS NULL OR c.classifications ?| p_classifications)
      AND (p_user_status IS NULL 
           OR (p_user_status = 'user' AND c.auth_user_id IS NOT NULL)
           OR (p_user_status = 'not_user' AND c.auth_user_id IS NULL))
      AND (NOT p_show_duplicates OR c.potential_duplicate = TRUE)
    ORDER BY
      CASE WHEN p_sort_by = 'created_at' AND p_sort_order = 'desc' THEN c.created_at END DESC NULLS LAST,
      CASE WHEN p_sort_by = 'created_at' AND p_sort_order = 'asc' THEN c.created_at END ASC NULLS LAST,
      CASE WHEN p_sort_by = 'name' AND p_sort_order = 'desc' THEN c.name END DESC NULLS LAST,
      CASE WHEN p_sort_by = 'name' AND p_sort_order = 'asc' THEN c.name END ASC NULLS LAST,
      CASE WHEN p_sort_by = 'updated_at' AND p_sort_order = 'desc' THEN c.updated_at END DESC NULLS LAST,
      CASE WHEN p_sort_by = 'updated_at' AND p_sort_order = 'asc' THEN c.updated_at END ASC NULLS LAST
    LIMIT p_limit
    OFFSET v_offset
  ) subq;

  RETURN jsonb_build_object(
    'success', TRUE,
    'data', jsonb_build_object(
      'contacts', COALESCE(v_contacts, '[]'::JSONB),
      'pagination', jsonb_build_object(
        'page', p_page,
        'limit', p_limit,
        'total', v_total_count,
        'totalPages', v_total_pages
      )
    )
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', SQLERRM,
      'code', SQLSTATE
    );
END;
$$;
```

---

### 1.3 RPC: `get_contact_full_v2`

**Purpose:** Get single contact with ALL related data in ONE query (replaces 4-5 DB calls).

```sql
CREATE OR REPLACE FUNCTION get_contact_full_v2(
  p_contact_id UUID,
  p_tenant_id UUID,
  p_is_live BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_contact JSONB;
BEGIN
  SELECT jsonb_build_object(
    -- Base contact fields
    'id', c.id,
    'name', c.name,
    'company_name', c.company_name,
    'type', c.type,
    'status', c.status,
    'classifications', c.classifications,
    'tags', COALESCE(c.tags, '[]'::JSONB),
    'compliance_numbers', COALESCE(c.compliance_numbers, '[]'::JSONB),
    'notes', c.notes,
    'salutation', c.salutation,
    'designation', c.designation,
    'department', c.department,
    'registration_number', c.registration_number,
    'parent_contact_ids', c.parent_contact_ids,
    'potential_duplicate', c.potential_duplicate,
    'auth_user_id', c.auth_user_id,
    'tenant_id', c.tenant_id,
    'is_live', c.is_live,
    'created_at', c.created_at,
    'updated_at', c.updated_at,
    'created_by', c.created_by,
    
    -- Display name computed in DB
    'displayName', CASE 
      WHEN c.type = 'corporate' THEN COALESCE(c.company_name, 'Unnamed Company')
      ELSE COALESCE(
        CASE WHEN c.salutation IS NOT NULL THEN c.salutation || '. ' ELSE '' END || c.name,
        'Unnamed Contact'
      )
    END,
    
    -- ALL contact channels (not just primary)
    'contact_channels', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', ch.id,
          'channel_type', ch.channel_type,
          'value', ch.value,
          'country_code', ch.country_code,
          'is_primary', ch.is_primary,
          'is_verified', ch.is_verified,
          'notes', ch.notes
        ) ORDER BY ch.is_primary DESC, ch.created_at
      )
      FROM t_contact_channels ch
      WHERE ch.contact_id = c.id
    ), '[]'::JSONB),
    
    -- ALL addresses
    'addresses', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', a.id,
          'type', a.type,
          'label', a.label,
          'address_line1', a.address_line1,
          'address_line2', a.address_line2,
          'city', a.city,
          'state_code', a.state_code,
          'country_code', a.country_code,
          'postal_code', a.postal_code,
          'google_pin', a.google_pin,
          'is_primary', a.is_primary,
          'notes', a.notes
        ) ORDER BY a.is_primary DESC, a.created_at
      )
      FROM t_contact_addresses a
      WHERE a.contact_id = c.id
    ), '[]'::JSONB),
    
    -- Backward compatibility alias
    'contact_addresses', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', a.id,
          'type', a.type,
          'label', a.label,
          'address_line1', a.address_line1,
          'address_line2', a.address_line2,
          'city', a.city,
          'state_code', a.state_code,
          'country_code', a.country_code,
          'postal_code', a.postal_code,
          'google_pin', a.google_pin,
          'is_primary', a.is_primary,
          'notes', a.notes
        ) ORDER BY a.is_primary DESC, a.created_at
      )
      FROM t_contact_addresses a
      WHERE a.contact_id = c.id
    ), '[]'::JSONB),
    
    -- Parent contacts
    'parent_contacts', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', p.id,
          'name', p.name,
          'company_name', p.company_name,
          'type', p.type,
          'status', p.status
        )
      )
      FROM t_contacts p
      WHERE p.id = ANY(
        SELECT jsonb_array_elements_text(c.parent_contact_ids)::UUID
      )
        AND p.is_live = p_is_live
        AND p.tenant_id = p_tenant_id
    ), '[]'::JSONB),
    
    -- Child contacts (contact_persons)
    'contact_persons', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', child.id,
          'name', child.name,
          'salutation', child.salutation,
          'designation', child.designation,
          'department', child.department,
          'type', child.type,
          'status', child.status,
          'contact_channels', COALESCE((
            SELECT jsonb_agg(
              jsonb_build_object(
                'id', ch2.id,
                'channel_type', ch2.channel_type,
                'value', ch2.value,
                'country_code', ch2.country_code,
                'is_primary', ch2.is_primary
              )
            )
            FROM t_contact_channels ch2
            WHERE ch2.contact_id = child.id
          ), '[]'::JSONB)
        )
      )
      FROM t_contacts child
      WHERE child.parent_contact_ids @> jsonb_build_array(c.id::TEXT)
        AND child.is_live = p_is_live
        AND child.tenant_id = p_tenant_id
        AND child.status != 'archived'
    ), '[]'::JSONB)
  )
  INTO v_contact
  FROM t_contacts c
  WHERE c.id = p_contact_id
    AND c.tenant_id = p_tenant_id
    AND c.is_live = p_is_live;

  IF v_contact IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'Contact not found',
      'code', 'NOT_FOUND'
    );
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'data', v_contact
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', SQLERRM,
      'code', SQLSTATE
    );
END;
$$;
```

---

### 1.4 RPC: `create_contact_idempotent_v2`

**Purpose:** Create contact with idempotency protection and bulk inserts (no loops).

```sql
CREATE OR REPLACE FUNCTION create_contact_idempotent_v2(
  p_idempotency_key UUID,
  p_contact_data JSONB,
  p_contact_channels JSONB DEFAULT '[]'::JSONB,
  p_addresses JSONB DEFAULT '[]'::JSONB,
  p_contact_persons JSONB DEFAULT '[]'::JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_contact_id UUID;
  v_existing_id UUID;
  v_person RECORD;
  v_person_contact_id UUID;
BEGIN
  -- STEP 1: Idempotency check (atomic)
  INSERT INTO api_idempotency (key, resource_type)
  VALUES (p_idempotency_key, 'contact')
  ON CONFLICT (key) DO NOTHING;

  -- If conflict (already processed), return existing contact
  IF NOT FOUND THEN
    SELECT resource_id INTO v_existing_id
    FROM api_idempotency
    WHERE key = p_idempotency_key;
    
    IF v_existing_id IS NOT NULL THEN
      RETURN jsonb_build_object(
        'success', TRUE,
        'data', (SELECT to_jsonb(c.*) FROM t_contacts c WHERE c.id = v_existing_id),
        'was_duplicate', TRUE,
        'message', 'Contact already created with this idempotency key'
      );
    END IF;
  END IF;

  -- STEP 2: Create main contact
  INSERT INTO t_contacts (
    type, status, name, company_name, registration_number,
    salutation, designation, department, is_primary_contact,
    classifications, tags, compliance_numbers, notes,
    parent_contact_ids, tenant_id, auth_user_id, created_by, is_live
  )
  VALUES (
    (p_contact_data->>'type')::TEXT,
    COALESCE((p_contact_data->>'status')::TEXT, 'active'),
    (p_contact_data->>'name')::TEXT,
    (p_contact_data->>'company_name')::TEXT,
    (p_contact_data->>'registration_number')::TEXT,
    (p_contact_data->>'salutation')::TEXT,
    (p_contact_data->>'designation')::TEXT,
    (p_contact_data->>'department')::TEXT,
    COALESCE((p_contact_data->>'is_primary_contact')::BOOLEAN, FALSE),
    COALESCE(p_contact_data->'classifications', '[]'::JSONB),
    COALESCE(p_contact_data->'tags', '[]'::JSONB),
    COALESCE(p_contact_data->'compliance_numbers', '[]'::JSONB),
    (p_contact_data->>'notes')::TEXT,
    COALESCE(p_contact_data->'parent_contact_ids', '[]'::JSONB),
    (p_contact_data->>'tenant_id')::UUID,
    (p_contact_data->>'auth_user_id')::UUID,
    (p_contact_data->>'created_by')::UUID,
    COALESCE((p_contact_data->>'is_live')::BOOLEAN, TRUE)
  )
  RETURNING id INTO v_contact_id;

  -- STEP 3: Bulk insert channels (no loop!)
  IF jsonb_array_length(p_contact_channels) > 0 THEN
    INSERT INTO t_contact_channels (contact_id, channel_type, value, country_code, is_primary, is_verified, notes)
    SELECT 
      v_contact_id,
      x.channel_type,
      x.value,
      x.country_code,
      COALESCE(x.is_primary, FALSE),
      COALESCE(x.is_verified, FALSE),
      x.notes
    FROM jsonb_to_recordset(p_contact_channels) AS x(
      channel_type TEXT, value TEXT, country_code TEXT, 
      is_primary BOOLEAN, is_verified BOOLEAN, notes TEXT
    );
  END IF;

  -- STEP 4: Bulk insert addresses (no loop!)
  IF jsonb_array_length(p_addresses) > 0 THEN
    INSERT INTO t_contact_addresses (contact_id, type, label, address_line1, address_line2, city, state_code, country_code, postal_code, google_pin, is_primary, notes)
    SELECT 
      v_contact_id,
      COALESCE(x.type, x.address_type),
      x.label,
      COALESCE(x.address_line1, x.line1),
      COALESCE(x.address_line2, x.line2),
      x.city,
      COALESCE(x.state_code, x.state),
      COALESCE(x.country_code, x.country, 'IN'),
      x.postal_code,
      x.google_pin,
      COALESCE(x.is_primary, FALSE),
      x.notes
    FROM jsonb_to_recordset(p_addresses) AS x(
      type TEXT, address_type TEXT, label TEXT, 
      address_line1 TEXT, line1 TEXT, address_line2 TEXT, line2 TEXT,
      city TEXT, state_code TEXT, state TEXT, country_code TEXT, country TEXT,
      postal_code TEXT, google_pin TEXT, is_primary BOOLEAN, notes TEXT
    );
  END IF;

  -- STEP 5: Create contact persons (needs loop for nested channels)
  IF jsonb_array_length(p_contact_persons) > 0 THEN
    FOR v_person IN
      SELECT * FROM jsonb_to_recordset(p_contact_persons) AS x(
        name TEXT, salutation TEXT, designation TEXT, department TEXT,
        is_primary BOOLEAN, notes TEXT, contact_channels JSONB
      )
    LOOP
      INSERT INTO t_contacts (
        type, status, name, salutation, designation, department,
        is_primary_contact, parent_contact_ids, classifications,
        tags, compliance_numbers, notes, tenant_id, created_by, is_live
      )
      VALUES (
        'individual', 'active', v_person.name, v_person.salutation,
        v_person.designation, v_person.department,
        COALESCE(v_person.is_primary, FALSE),
        jsonb_build_array(v_contact_id),
        '["team_member"]'::JSONB,
        '[]'::JSONB, '[]'::JSONB, v_person.notes,
        (p_contact_data->>'tenant_id')::UUID,
        (p_contact_data->>'created_by')::UUID,
        COALESCE((p_contact_data->>'is_live')::BOOLEAN, TRUE)
      )
      RETURNING id INTO v_person_contact_id;

      -- Bulk insert person channels
      IF v_person.contact_channels IS NOT NULL AND jsonb_array_length(v_person.contact_channels) > 0 THEN
        INSERT INTO t_contact_channels (contact_id, channel_type, value, country_code, is_primary, is_verified, notes)
        SELECT 
          v_person_contact_id,
          x.channel_type, x.value, x.country_code,
          COALESCE(x.is_primary, FALSE),
          COALESCE(x.is_verified, FALSE),
          x.notes
        FROM jsonb_to_recordset(v_person.contact_channels) AS x(
          channel_type TEXT, value TEXT, country_code TEXT,
          is_primary BOOLEAN, is_verified BOOLEAN, notes TEXT
        );
      END IF;
    END LOOP;
  END IF;

  -- STEP 6: Update idempotency record with resource_id
  UPDATE api_idempotency SET resource_id = v_contact_id WHERE key = p_idempotency_key;

  -- STEP 7: Return result
  RETURN jsonb_build_object(
    'success', TRUE,
    'data', jsonb_build_object('id', v_contact_id),
    'was_duplicate', FALSE,
    'message', 'Contact created successfully'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', SQLERRM,
      'code', 'CREATE_CONTACT_ERROR'
    );
END;
$$;
```

---

### 1.5 RPC: `update_contact_idempotent_v2`

**Purpose:** Update contact with idempotency and single transaction.

```sql
CREATE OR REPLACE FUNCTION update_contact_idempotent_v2(
  p_idempotency_key UUID,
  p_contact_id UUID,
  p_contact_data JSONB,
  p_contact_channels JSONB DEFAULT NULL,
  p_addresses JSONB DEFAULT NULL,
  p_contact_persons JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing_contact RECORD;
BEGIN
  -- STEP 1: Idempotency check
  INSERT INTO api_idempotency (key, resource_type, resource_id)
  VALUES (p_idempotency_key, 'contact_update', p_contact_id)
  ON CONFLICT (key) DO NOTHING;

  IF NOT FOUND THEN
    -- Already processed
    RETURN jsonb_build_object(
      'success', TRUE,
      'data', jsonb_build_object('id', p_contact_id),
      'was_duplicate', TRUE,
      'message', 'Update already processed with this idempotency key'
    );
  END IF;

  -- STEP 2: Check contact exists and not archived
  SELECT id, status INTO v_existing_contact
  FROM t_contacts
  WHERE id = p_contact_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'Contact not found',
      'code', 'NOT_FOUND'
    );
  END IF;

  IF v_existing_contact.status = 'archived' THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'Cannot update archived contact',
      'code', 'CONTACT_ARCHIVED'
    );
  END IF;

  -- STEP 3: Update main contact
  UPDATE t_contacts SET
    name = COALESCE((p_contact_data->>'name')::TEXT, name),
    company_name = COALESCE((p_contact_data->>'company_name')::TEXT, company_name),
    registration_number = COALESCE((p_contact_data->>'registration_number')::TEXT, registration_number),
    salutation = COALESCE((p_contact_data->>'salutation')::TEXT, salutation),
    designation = COALESCE((p_contact_data->>'designation')::TEXT, designation),
    department = COALESCE((p_contact_data->>'department')::TEXT, department),
    is_primary_contact = COALESCE((p_contact_data->>'is_primary_contact')::BOOLEAN, is_primary_contact),
    classifications = COALESCE(p_contact_data->'classifications', classifications),
    tags = COALESCE(p_contact_data->'tags', tags),
    compliance_numbers = COALESCE(p_contact_data->'compliance_numbers', compliance_numbers),
    notes = COALESCE((p_contact_data->>'notes')::TEXT, notes),
    parent_contact_ids = COALESCE(p_contact_data->'parent_contact_ids', parent_contact_ids),
    updated_by = (p_contact_data->>'updated_by')::UUID,
    updated_at = NOW()
  WHERE id = p_contact_id;

  -- STEP 4: Replace channels if provided
  IF p_contact_channels IS NOT NULL THEN
    DELETE FROM t_contact_channels WHERE contact_id = p_contact_id;
    
    IF jsonb_array_length(p_contact_channels) > 0 THEN
      INSERT INTO t_contact_channels (contact_id, channel_type, value, country_code, is_primary, is_verified, notes)
      SELECT 
        p_contact_id,
        x.channel_type, x.value, x.country_code,
        COALESCE(x.is_primary, FALSE),
        COALESCE(x.is_verified, FALSE),
        x.notes
      FROM jsonb_to_recordset(p_contact_channels) AS x(
        channel_type TEXT, value TEXT, country_code TEXT,
        is_primary BOOLEAN, is_verified BOOLEAN, notes TEXT
      );
    END IF;
  END IF;

  -- STEP 5: Replace addresses if provided
  IF p_addresses IS NOT NULL THEN
    DELETE FROM t_contact_addresses WHERE contact_id = p_contact_id;
    
    IF jsonb_array_length(p_addresses) > 0 THEN
      INSERT INTO t_contact_addresses (contact_id, type, label, address_line1, address_line2, city, state_code, country_code, postal_code, google_pin, is_primary, notes)
      SELECT 
        p_contact_id,
        COALESCE(x.type, x.address_type),
        x.label,
        COALESCE(x.address_line1, x.line1),
        COALESCE(x.address_line2, x.line2),
        x.city,
        COALESCE(x.state_code, x.state),
        COALESCE(x.country_code, x.country, 'IN'),
        x.postal_code,
        x.google_pin,
        COALESCE(x.is_primary, FALSE),
        x.notes
      FROM jsonb_to_recordset(p_addresses) AS x(
        type TEXT, address_type TEXT, label TEXT,
        address_line1 TEXT, line1 TEXT, address_line2 TEXT, line2 TEXT,
        city TEXT, state_code TEXT, state TEXT, country_code TEXT, country TEXT,
        postal_code TEXT, google_pin TEXT, is_primary BOOLEAN, notes TEXT
      );
    END IF;
  END IF;

  -- Contact persons handling is more complex (create/update/delete)
  -- For now, let existing logic handle it or implement similar pattern

  RETURN jsonb_build_object(
    'success', TRUE,
    'data', jsonb_build_object('id', p_contact_id),
    'was_duplicate', FALSE,
    'message', 'Contact updated successfully'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', SQLERRM,
      'code', 'UPDATE_CONTACT_ERROR'
    );
END;
$$;
```

---

## 🔧 PART 2: EDGE FUNCTION CHANGES

### 2.1 Key Changes for `index.ts`

```typescript
// Add at the START of the handler
const traceId = crypto.randomUUID();
const startTime = Date.now();

// Structured logging
console.log(JSON.stringify({
  trace_id: traceId,
  event: 'request.start',
  method: req.method,
  path: new URL(req.url).pathname,
  tenant_id: tenantId,
  timestamp: new Date().toISOString()
}));

// Require idempotency key for write operations
if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
  const idempotencyKey = req.headers.get('x-idempotency-key');
  if (!idempotencyKey) {
    return new Response(
      JSON.stringify({ 
        error: 'x-idempotency-key header required for write operations',
        code: 'MISSING_IDEMPOTENCY_KEY',
        trace_id: traceId
      }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

// Fire-and-forget audit (don't await!)
auditLogger.log({
  tenantId,
  action: ContactAuditActions.LIST,
  // ...
}).catch(e => console.error(JSON.stringify({ 
  trace_id: traceId, 
  event: 'audit.error', 
  error: e.message 
})));

// Include metadata in ALL responses
return new Response(
  JSON.stringify({
    success: true,
    data: result,
    metadata: {
      trace_id: traceId,
      duration_ms: Date.now() - startTime,
      timestamp: new Date().toISOString()
    }
  }),
  { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
);
```

---

### 2.2 Key Changes for `contactService.ts`

```typescript
// REMOVE: enrichContactsWithRelatedData method entirely

// SIMPLIFY: listContacts
async listContacts(filters: any) {
  const { data: rpcResult, error } = await this.supabase.rpc('list_contacts_with_channels_v2', {
    p_tenant_id: this.tenantId,
    p_is_live: this.isLive,
    p_page: filters.page || 1,
    p_limit: Math.min(filters.limit || 20, 100),
    p_type: filters.type || null,
    p_status: filters.status || null,
    p_search: filters.search?.trim() || null,
    p_classifications: filters.classifications || null,
    p_user_status: filters.user_status || null,
    p_show_duplicates: filters.show_duplicates || false,
    p_include_inactive: filters.includeInactive || false,
    p_include_archived: filters.includeArchived || false,
    p_sort_by: filters.sort_by || 'created_at',
    p_sort_order: filters.sort_order || 'desc'
  });

  if (error || !rpcResult?.success) {
    throw new Error(rpcResult?.error || error?.message || 'Failed to list contacts');
  }

  // Data already complete - no enrichment needed!
  return {
    contacts: rpcResult.data.contacts || [],
    pagination: rpcResult.data.pagination
  };
}

// SIMPLIFY: getContactById
async getContactById(contactId: string) {
  const { data: rpcResult, error } = await this.supabase.rpc('get_contact_full_v2', {
    p_contact_id: contactId,
    p_tenant_id: this.tenantId,
    p_is_live: this.isLive
  });

  if (error || !rpcResult?.success) {
    if (rpcResult?.code === 'NOT_FOUND') return null;
    throw new Error(rpcResult?.error || error?.message || 'Failed to get contact');
  }

  // Everything included - no additional queries!
  return rpcResult.data;
}

// UPDATE: createContact with idempotency
async createContact(contactData: any, idempotencyKey: string) {
  const { data: rpcResult, error } = await this.supabase.rpc('create_contact_idempotent_v2', {
    p_idempotency_key: idempotencyKey,
    p_contact_data: {
      ...contactData,
      tenant_id: this.tenantId,
      is_live: this.isLive
    },
    p_contact_channels: contactData.contact_channels || [],
    p_addresses: contactData.addresses || [],
    p_contact_persons: contactData.contact_persons || []
  });

  if (error || !rpcResult?.success) {
    throw new Error(rpcResult?.error || error?.message || 'Failed to create contact');
  }

  if (rpcResult.was_duplicate) {
    console.log('Idempotent: returning existing contact');
  }

  return rpcResult.data;
}

// UPDATE: updateContact with idempotency
async updateContact(contactId: string, updateData: any, idempotencyKey: string) {
  const { data: rpcResult, error } = await this.supabase.rpc('update_contact_idempotent_v2', {
    p_idempotency_key: idempotencyKey,
    p_contact_id: contactId,
    p_contact_data: {
      ...updateData,
      is_live: this.isLive
    },
    p_contact_channels: updateData.contact_channels,
    p_addresses: updateData.addresses,
    p_contact_persons: updateData.contact_persons
  });

  if (error || !rpcResult?.success) {
    throw new Error(rpcResult?.error || error?.message || 'Failed to update contact');
  }

  return rpcResult.data;
}
```

---

## 📊 PART 3: EXPECTED RESULTS

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| List contacts DB calls | 3+ | 1 | **3x fewer** |
| Get contact DB calls | 4-5 | 1 | **5x fewer** |
| Create contact DB calls | 3+ | 1 | **3x fewer** |
| List contacts latency | ~300-500ms | ~50-100ms | **5x faster** |
| Get contact latency | ~400-600ms | ~50-80ms | **6x faster** |
| Retry safety | ❌ Duplicates | ✅ Idempotent | **Safe** |
| Observability | ❌ None | ✅ trace_id | **Debuggable** |

---

## ✅ PART 4: IMPLEMENTATION ORDER

### Phase 1: Database (Can Execute Immediately)
1. ✅ Create `api_idempotency` table
2. ✅ Create `list_contacts_with_channels_v2` RPC
3. ✅ Create `get_contact_full_v2` RPC
4. ✅ Create `create_contact_idempotent_v2` RPC
5. ✅ Create `update_contact_idempotent_v2` RPC

### Phase 2: Edge Service (After Phase 1)
1. Update `contactService.ts` to use new RPCs
2. Remove `enrichContactsWithRelatedData` method
3. Add idempotency key parameter to create/update

### Phase 3: Edge Handler (After Phase 2)
1. Add trace_id generation
2. Add idempotency key requirement
3. Add response timing
4. Make audit logging fire-and-forget

### Phase 4: API Layer (After Phase 3)
1. Generate idempotency keys for write requests
2. Pass to Edge function
3. Add trace_id to request headers

---

## 🧪 PART 5: TESTING

### Test New RPCs Directly in Supabase SQL Editor:

```sql
-- Test list_contacts_with_channels_v2
SELECT list_contacts_with_channels_v2(
  'your-tenant-uuid'::UUID,
  TRUE,  -- is_live
  1,     -- page
  10     -- limit
);

-- Test get_contact_full_v2
SELECT get_contact_full_v2(
  'contact-uuid'::UUID,
  'tenant-uuid'::UUID,
  TRUE
);

-- Test create_contact_idempotent_v2
SELECT create_contact_idempotent_v2(
  gen_random_uuid(),  -- idempotency key
  '{"type": "individual", "name": "Test", "tenant_id": "your-tenant-uuid", "is_live": true}'::JSONB,
  '[{"channel_type": "email", "value": "test@test.com", "is_primary": true}]'::JSONB
);
```

---

**Document Created**: For Claude Developer implementation
**Last Updated**: January 2025