# BBB Directory Integration - Technical Specification

**Version:** 1.0  
**Date:** 2024-11-19  
**Architecture:** UI Layer → API Layer → Edge Layer → Database  
**Stack:** React TypeScript → Axios Services → Supabase Edge Functions → PostgreSQL + pgvector

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Database Schema Reference](#2-database-schema-reference)
3. [Edge Layer Specifications](#3-edge-layer-specifications)
4. [API Layer Specifications](#4-api-layer-specifications)
5. [UI Layer Specifications](#5-ui-layer-specifications)
6. [Data Flow Diagrams](#6-data-flow-diagrams)
7. [Error Handling Standards](#7-error-handling-standards)
8. [Testing Requirements](#8-testing-requirements)

---

## 1. Architecture Overview

### 1.1 Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI LAYER                              │
│  React Components + TypeScript Interfaces + State Management │
│  Location: src/components/VaNi/bbb/* + src/pages/VaNi/*     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼ (Axios HTTP Calls)
┌─────────────────────────────────────────────────────────────┐
│                       API LAYER                              │
│     Service Layer with TypeScript Wrappers                   │
│     Location: src/services/bbbService.ts                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼ (HTTPS POST/GET/PUT/DELETE)
┌─────────────────────────────────────────────────────────────┐
│                      EDGE LAYER                              │
│         Supabase Edge Functions (Deno TypeScript)            │
│         Location: supabase/functions/bbb-*                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼ (SQL Queries + n8n Webhooks)
┌─────────────────────────────────────────────────────────────┐
│                   DATABASE + n8n                             │
│  PostgreSQL with pgvector + n8n AI Workflows                 │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 External Dependencies

| Service | Purpose | Environment Variable |
|---------|---------|---------------------|
| Supabase | Database + Auth + Edge Functions | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| n8n | AI workflows (OpenAI integration) | Webhook URLs (hardcoded) |
| OpenAI | Embeddings + Text generation | Managed by n8n |

---

## 2. Database Schema Reference

### 2.1 Existing Tables (No Changes)

**t_tenants** - Core tenant table (unchanged)

**t_tenant_profiles** - Modified with 2 new fields:
```sql
business_whatsapp_country_code VARCHAR(10)  -- NEW
business_whatsapp VARCHAR(20)               -- NEW
```

### 2.2 New BBB Tables

| Table Name | Purpose | Key Fields |
|------------|---------|------------|
| `t_business_groups` | Business networks/chapters | id, group_name, group_type, settings (JSONB) |
| `t_group_memberships` | Tenant membership in groups | id, tenant_id, group_id, profile_data (JSONB), embedding (vector) |
| `t_semantic_clusters` | AI-generated keyword clusters | id, membership_id, primary_term, related_terms[] |
| `t_search_query_cache` | Search result caching (30-day TTL) | id, group_id, query_normalized, results (JSONB) |
| `t_group_activity_logs` | Activity tracking | id, group_id, activity_type, activity_data (JSONB) |

**Seed Data:** BBB Bagyanagar chapter already created with `group_id` (to be retrieved).

---

## 3. Edge Layer Specifications

### 3.1 Edge Function: `business-groups`

**File:** `supabase/functions/business-groups/index.ts`

**Base URL:** `https://[PROJECT_REF].supabase.co/functions/v1/business-groups`

#### Route 1: Get All Groups

**Endpoint:** `GET /business-groups?group_type={type}`

**Query Parameters:**
```typescript
{
  group_type?: 'bbb_chapter' | 'all'  // Optional, defaults to 'all'
}
```

**Response:**
```typescript
{
  success: true,
  groups: [
    {
      id: string,              // UUID
      group_name: string,
      group_type: string,
      description: string,
      chapter: string | null,  // From settings.chapter
      branch: string | null,   // From settings.branch
      member_count: number,
      is_active: boolean,
      created_at: string
    }
  ]
}
```

**SQL Query:**
```sql
SELECT 
  id,
  group_name,
  group_type,
  description,
  settings->>'chapter' as chapter,
  settings->>'branch' as branch,
  member_count,
  is_active,
  created_at
FROM t_business_groups
WHERE 
  (${group_type} = 'all' OR group_type = ${group_type})
  AND is_active = true
ORDER BY group_name;
```

**Error Handling:**
- 500: Database connection error
- 404: No groups found

---

#### Route 2: Get Specific Group

**Endpoint:** `GET /business-groups/:groupId`

**Path Parameters:**
```typescript
{
  groupId: string  // UUID
}
```

**Response:**
```typescript
{
  success: true,
  group: {
    id: string,
    group_name: string,
    group_type: string,
    description: string,
    settings: object,        // Full JSONB
    member_count: number,
    admin_tenant_id: string | null,
    is_active: boolean,
    created_at: string,
    updated_at: string
  }
}
```

**SQL Query:**
```sql
SELECT *
FROM t_business_groups
WHERE id = ${groupId}
  AND is_active = true;
```

**Error Handling:**
- 404: Group not found
- 500: Database error

---

#### Route 3: Verify Group Access

**Endpoint:** `POST /business-groups/verify-access`

**Request Body:**
```typescript
{
  group_id: string,              // UUID
  password: string,              // Plain text password
  access_type: 'user' | 'admin'  // Type of access requested
}
```

**Response (Success):**
```typescript
{
  success: true,
  access_granted: true,
  access_level: 'user' | 'admin',
  group_id: string,
  group_name: string,
  redirect_to: string  // Frontend route to navigate to
}
```

**Response (Failure):**
```typescript
{
  success: false,
  access_granted: false,
  error: 'Invalid password'
}
```

**Logic:**
```typescript
// 1. Get group settings
const { data: group } = await supabase
  .from('t_business_groups')
  .select('settings, group_name')
  .eq('id', group_id)
  .single();

// 2. Extract passwords from settings
const userPassword = group.settings.access.user_password;
const adminPassword = group.settings.access.admin_password;

// 3. Verify
if (access_type === 'admin' && password === adminPassword) {
  return {
    success: true,
    access_granted: true,
    access_level: 'admin',
    redirect_to: '/vani/channels/bbb/admin'
  };
} else if (access_type === 'user' && password === userPassword) {
  return {
    success: true,
    access_granted: true,
    access_level: 'user',
    redirect_to: '/vani/channels/bbb/onboarding'
  };
} else {
  return {
    success: false,
    access_granted: false,
    error: 'Invalid password'
  };
}
```

**Error Handling:**
- 400: Missing required fields
- 404: Group not found
- 401: Invalid password
- 500: Database error

**Security Notes:**
- Passwords stored in JSONB are plain text for MVP
- Future: Hash passwords using bcrypt
- Rate limit: 5 attempts per IP per 15 minutes

---

### 3.2 Edge Function: `group-memberships`

**File:** `supabase/functions/group-memberships/index.ts`

**Base URL:** `https://[PROJECT_REF].supabase.co/functions/v1/group-memberships`

#### Route 1: Create Membership

**Endpoint:** `POST /group-memberships`

**Request Headers:**
```typescript
{
  'Authorization': 'Bearer [token]',
  'x-tenant-id': string  // Current tenant ID
}
```

**Request Body:**
```typescript
{
  group_id: string,  // UUID
  profile_data?: {
    mobile_number?: string,
    member_number?: string
  }
}
```

**Response:**
```typescript
{
  success: true,
  membership_id: string,  // UUID
  tenant_id: string,
  group_id: string,
  status: 'draft',
  created_at: string
}
```

**SQL Query:**
```sql
INSERT INTO t_group_memberships (
  tenant_id,
  group_id,
  profile_data,
  status,
  is_active
) VALUES (
  ${tenant_id},
  ${group_id},
  ${profile_data}::jsonb,
  'draft',
  true
)
RETURNING id, tenant_id, group_id, status, created_at;
```

**Error Handling:**
- 400: Missing group_id
- 409: Membership already exists (UNIQUE constraint violation)
- 404: Group not found
- 500: Database error

---

#### Route 2: Get Membership with Profile

**Endpoint:** `GET /group-memberships/:membershipId`

**Response:**
```typescript
{
  success: true,
  membership: {
    membership_id: string,
    tenant_id: string,
    group_id: string,
    status: string,
    joined_at: string,
    profile_data: object,  // JSONB
    
    // Joined from t_tenant_profiles
    tenant_profile: {
      business_name: string,
      business_email: string,
      business_phone: string,
      business_whatsapp: string,
      business_whatsapp_country_code: string,
      city: string,
      state_code: string,
      industry_id: string,
      website_url: string,
      logo_url: string
    }
  }
}
```

**SQL Query:**
```sql
SELECT 
  gm.id as membership_id,
  gm.tenant_id,
  gm.group_id,
  gm.status,
  gm.joined_at,
  gm.profile_data,
  
  -- Tenant profile fields
  tp.business_name,
  tp.business_email,
  tp.business_phone,
  tp.business_whatsapp,
  tp.business_whatsapp_country_code,
  tp.city,
  tp.state_code,
  tp.industry_id,
  tp.website_url,
  tp.logo_url
  
FROM t_group_memberships gm
JOIN t_tenant_profiles tp ON tp.tenant_id = gm.tenant_id
WHERE gm.id = ${membershipId}
  AND gm.is_active = true;
```

**Error Handling:**
- 404: Membership not found
- 500: Database error

---

#### Route 3: Update Membership Profile

**Endpoint:** `PUT /group-memberships/:membershipId`

**Request Body:**
```typescript
{
  profile_data?: {
    generation_method?: 'manual' | 'website',
    short_description?: string,
    ai_enhanced_description?: string,
    website_url?: string,
    website_scraped_data?: object,
    suggested_keywords?: string[],
    approved_keywords?: string[],
    semantic_tags?: string[]
  },
  status?: 'draft' | 'pending' | 'active' | 'inactive'
}
```

**Response:**
```typescript
{
  success: true,
  membership_id: string,
  updated_fields: string[],  // List of fields updated
  profile_data: object       // Current profile_data after update
}
```

**SQL Logic:**
```typescript
// Use JSONB merge operator ||
UPDATE t_group_memberships
SET 
  profile_data = profile_data || ${new_profile_data}::jsonb,
  status = COALESCE(${status}, status),
  updated_at = CURRENT_TIMESTAMP
WHERE id = ${membershipId}
RETURNING id, profile_data;
```

**Error Handling:**
- 400: Invalid request body
- 404: Membership not found
- 500: Database error

---

#### Route 4: Get Group Members (Admin)

**Endpoint:** `GET /group-memberships/group/:groupId`

**Query Parameters:**
```typescript
{
  status?: 'all' | 'active' | 'pending' | 'inactive',  // Default: 'all'
  limit?: number,   // Default: 50, Max: 100
  offset?: number   // Default: 0
}
```

**Response:**
```typescript
{
  success: true,
  memberships: [
    {
      membership_id: string,
      tenant_id: string,
      status: string,
      joined_at: string,
      mobile_number: string | null,  // From profile_data
      
      // From tenant_profile
      business_name: string,
      business_email: string,
      city: string,
      logo_url: string
    }
  ],
  pagination: {
    total_count: number,
    limit: number,
    offset: number,
    has_more: boolean
  }
}
```

**SQL Query:**
```sql
SELECT 
  gm.id as membership_id,
  gm.tenant_id,
  gm.status,
  gm.joined_at,
  gm.profile_data->>'mobile_number' as mobile_number,
  tp.business_name,
  tp.business_email,
  tp.city,
  tp.logo_url,
  
  -- Total count for pagination
  COUNT(*) OVER() as total_count
  
FROM t_group_memberships gm
JOIN t_tenant_profiles tp ON tp.tenant_id = gm.tenant_id
WHERE 
  gm.group_id = ${groupId}
  AND gm.is_active = true
  AND (${status} = 'all' OR gm.status = ${status})
ORDER BY gm.joined_at DESC
LIMIT ${limit}
OFFSET ${offset};
```

**Error Handling:**
- 400: Invalid query parameters
- 404: Group not found
- 500: Database error

---

#### Route 5: Delete Membership (Soft Delete)

**Endpoint:** `DELETE /group-memberships/:membershipId`

**Response:**
```typescript
{
  success: true,
  membership_id: string,
  deleted_at: string
}
```

**SQL Query:**
```sql
UPDATE t_group_memberships
SET 
  is_active = false,
  status = 'inactive',
  updated_at = CURRENT_TIMESTAMP
WHERE id = ${membershipId}
RETURNING id, updated_at;
```

**Error Handling:**
- 404: Membership not found
- 500: Database error

---

### 3.3 Edge Function: `bbb-profiles`

**File:** `supabase/functions/bbb-profiles/index.ts`

**Base URL:** `https://[PROJECT_REF].supabase.co/functions/v1/bbb-profiles`

**n8n Webhook URLs (Constants):**
```typescript
const N8N_WEBHOOKS = {
  enhance: 'https://n8n.srv1017206.hstgr.cloud/webhook-test/profile-enhance',
  scrape: 'https://n8n.srv1017206.hstgr.cloud/webhook-test/website-scrape',
  clusters: 'https://n8n.srv1017206.hstgr.cloud/webhook-test/generate-clusters',
  embed: 'https://n8n.srv1017206.hstgr.cloud/webhook-test/profile-ingest'
};
```

#### Route 1: AI Enhancement

**Endpoint:** `POST /bbb-profiles/enhance`

**Request Body:**
```typescript
{
  membership_id: string,
  short_description: string  // 1-2 sentences from user
}
```

**Response:**
```typescript
{
  success: true,
  ai_enhanced_description: string,  // 6-8 lines
  suggested_keywords: string[],     // 5-10 keywords
  processing_time_ms: number
}
```

**Edge Function Logic:**
```typescript
// 1. Get tenant profile for context
const { data: membership } = await supabase
  .from('t_group_memberships')
  .select(`
    *,
    tenant_profile:t_tenant_profiles(
      business_name,
      city,
      industry_id
    )
  `)
  .eq('id', membership_id)
  .single();

// 2. Call n8n enhancement workflow
const startTime = Date.now();
const response = await fetch(N8N_WEBHOOKS.enhance, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    membership_id,
    short_description,
    business_context: {
      business_name: membership.tenant_profile.business_name,
      city: membership.tenant_profile.city,
      industry: membership.tenant_profile.industry_id
    }
  })
});

const result = await response.json();
const processingTime = Date.now() - startTime;

// 3. Return result (DO NOT save to DB yet - UI will do that)
return {
  success: true,
  ai_enhanced_description: result.enhanced_description,
  suggested_keywords: result.keywords,
  processing_time_ms: processingTime
};
```

**Error Handling:**
- 400: Missing short_description
- 404: Membership not found
- 500: n8n webhook failed
- 504: n8n timeout (>30s)

---

#### Route 2: Website Scraping

**Endpoint:** `POST /bbb-profiles/scrape-website`

**Request Body:**
```typescript
{
  membership_id: string,
  website_url: string
}
```

**Response:**
```typescript
{
  success: true,
  ai_enhanced_description: string,
  suggested_keywords: string[],
  scraped_data: {
    title: string,
    meta_description: string,
    content_snippets: string[]
  }
}
```

**Edge Function Logic:**
```typescript
// 1. Validate URL
const urlPattern = /^https?:\/\/.+\..+/;
if (!urlPattern.test(website_url)) {
  throw new Error('Invalid URL format');
}

// 2. Call n8n scraping workflow
const response = await fetch(N8N_WEBHOOKS.scrape, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    membership_id,
    website_url
  })
});

const result = await response.json();

// 3. Return scraped + enhanced data
return {
  success: true,
  ai_enhanced_description: result.enhanced_description,
  suggested_keywords: result.keywords,
  scraped_data: result.scraped_data
};
```

**Error Handling:**
- 400: Invalid URL
- 404: Membership not found
- 422: Website inaccessible
- 500: n8n workflow failed

---

#### Route 3: Generate Semantic Clusters

**Endpoint:** `POST /bbb-profiles/generate-clusters`

**Request Body:**
```typescript
{
  membership_id: string,
  profile_text: string,
  keywords: string[]
}
```

**Response:**
```typescript
{
  success: true,
  clusters_generated: number,
  clusters: [
    {
      primary_term: string,
      related_terms: string[],
      category: string,
      confidence_score: number
    }
  ]
}
```

**Edge Function Logic:**
```typescript
// 1. Call n8n cluster generation workflow
const response = await fetch(N8N_WEBHOOKS.clusters, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    membership_id,
    profile_text,
    keywords
  })
});

const result = await response.json();

// 2. Store clusters in database
const clustersToInsert = result.clusters.map(cluster => ({
  membership_id,
  primary_term: cluster.primary_term,
  related_terms: cluster.related_terms,
  category: cluster.category,
  confidence_score: cluster.confidence_score,
  is_active: true
}));

const { data: insertedClusters } = await supabase
  .from('t_semantic_clusters')
  .insert(clustersToInsert)
  .select();

// 3. Return result
return {
  success: true,
  clusters_generated: insertedClusters.length,
  clusters: insertedClusters
};
```

**Error Handling:**
- 400: Missing required fields
- 404: Membership not found
- 500: Database or n8n error

---

#### Route 4: Save Profile & Generate Embedding

**Endpoint:** `POST /bbb-profiles/save`

**Request Body:**
```typescript
{
  membership_id: string,
  profile_data: {
    generation_method: 'manual' | 'website',
    short_description: string,
    ai_enhanced_description: string,
    approved_keywords: string[],
    website_url?: string,
    website_scraped_data?: object
  },
  trigger_embedding: boolean  // Should we generate vector embedding?
}
```

**Response:**
```typescript
{
  success: true,
  membership_id: string,
  status: 'active',  // Updated to active after save
  embedding_generated: boolean
}
```

**Edge Function Logic:**
```typescript
// 1. Update membership with profile_data
const { data: membership } = await supabase
  .from('t_group_memberships')
  .update({
    profile_data: profile_data,
    status: 'active',
    updated_at: new Date().toISOString()
  })
  .eq('id', membership_id)
  .select(`
    *,
    tenant_profile:t_tenant_profiles(business_name, city, industry_id)
  `)
  .single();

// 2. If trigger_embedding = true, call n8n to generate embedding
let embeddingGenerated = false;
if (trigger_embedding) {
  // Combine business info + profile for embedding
  const textToEmbed = `
    ${membership.tenant_profile.business_name}
    ${membership.tenant_profile.industry_id}
    ${membership.tenant_profile.city}
    ${profile_data.ai_enhanced_description}
  `.trim();
  
  const embeddingResponse = await fetch(N8N_WEBHOOKS.embed, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      membership_id,
      text: textToEmbed
    })
  });
  
  // n8n workflow will update the embedding directly in DB
  embeddingGenerated = embeddingResponse.ok;
}

// 3. Return success
return {
  success: true,
  membership_id,
  status: 'active',
  embedding_generated: embeddingGenerated
};
```

**Error Handling:**
- 400: Missing required fields
- 404: Membership not found
- 500: Database or n8n error

---

### 3.4 Edge Function: `bbb-search`

**File:** `supabase/functions/bbb-search/index.ts`

**Base URL:** `https://[PROJECT_REF].supabase.co/functions/v1/bbb-search`

#### Route 1: Search Directory

**Endpoint:** `POST /bbb-search`

**Request Body:**
```typescript
{
  group_id: string,
  query: string,
  limit?: number,        // Default: 5, Max: 20
  use_cache?: boolean    // Default: true
}
```

**Response:**
```typescript
{
  success: true,
  query: string,
  results_count: number,
  from_cache: boolean,
  search_time_ms: number,
  results: [
    {
      membership_id: string,
      tenant_id: string,
      business_name: string,
      business_email: string,
      mobile_number: string,
      city: string,
      industry: string,
      profile_snippet: string,  // First 200 chars
      similarity_score: number, // 0.0 - 1.0
      match_type: 'vector' | 'keyword' | 'semantic',
      logo_url: string | null
    }
  ]
}
```

**Edge Function Logic:**
```typescript
const startTime = Date.now();

// 1. Normalize query
const queryNormalized = query.toLowerCase().trim();

// 2. Check cache (if enabled)
if (use_cache) {
  const { data: cached } = await supabase
    .from('t_search_query_cache')
    .select('results, hit_count')
    .eq('group_id', group_id)
    .eq('query_normalized', queryNormalized)
    .gte('expires_at', new Date().toISOString())
    .maybeSingle();
  
  if (cached) {
    // Update hit count
    await supabase
      .from('t_search_query_cache')
      .update({ 
        hit_count: cached.hit_count + 1,
        last_accessed_at: new Date().toISOString()
      })
      .eq('group_id', group_id)
      .eq('query_normalized', queryNormalized);
    
    return {
      ...cached.results,
      from_cache: true,
      search_time_ms: Date.now() - startTime
    };
  }
}

// 3. Cache miss - call n8n search workflow
const searchResponse = await fetch(N8N_WEBHOOKS.search, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    group_id,
    query,
    limit: limit || 5
  })
});

const searchResults = await searchResponse.json();

// 4. Store in cache
if (use_cache && searchResults.results.length > 0) {
  await supabase
    .from('t_search_query_cache')
    .insert({
      group_id,
      query_text: query,
      query_normalized: queryNormalized,
      results: searchResults,
      hit_count: 1,
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
    });
}

// 5. Return results
return {
  ...searchResults,
  from_cache: false,
  search_time_ms: Date.now() - startTime
};
```

**Error Handling:**
- 400: Missing query or group_id
- 404: Group not found
- 500: Database or n8n error
- 504: Search timeout (>10s)

**Performance Targets:**
- Cache hit: < 100ms
- Cache miss: < 2000ms
- Cache hit rate: > 70%

---

### 3.5 Edge Function: `bbb-admin`

**File:** `supabase/functions/bbb-admin/index.ts`

**Base URL:** `https://[PROJECT_REF].supabase.co/functions/v1/bbb-admin`

#### Route 1: Get Dashboard Stats

**Endpoint:** `GET /bbb-admin/stats/:groupId`

**Response:**
```typescript
{
  success: true,
  stats: {
    total_members: number,
    active_members: number,
    pending_members: number,
    inactive_members: number,
    suspended_members: number
  },
  recent_activity: [
    {
      activity_type: string,
      tenant_name: string,
      timestamp: string,
      details: string
    }
  ]
}
```

**SQL Query:**
```sql
-- Stats
SELECT 
  COUNT(*) FILTER (WHERE is_active = true) as total_members,
  COUNT(*) FILTER (WHERE status = 'active') as active_members,
  COUNT(*) FILTER (WHERE status = 'pending') as pending_members,
  COUNT(*) FILTER (WHERE status = 'inactive') as inactive_members,
  COUNT(*) FILTER (WHERE status = 'suspended') as suspended_members
FROM t_group_memberships
WHERE group_id = ${groupId};

-- Recent activity
SELECT 
  al.activity_type,
  tp.business_name as tenant_name,
  al.created_at as timestamp,
  al.activity_data->>'details' as details
FROM t_group_activity_logs al
LEFT JOIN t_tenant_profiles tp ON tp.tenant_id = al.tenant_id
WHERE al.group_id = ${groupId}
ORDER BY al.created_at DESC
LIMIT 10;
```

**Error Handling:**
- 404: Group not found
- 500: Database error

---

#### Route 2: Update Membership Status

**Endpoint:** `PUT /bbb-admin/memberships/:membershipId/status`

**Request Body:**
```typescript
{
  status: 'active' | 'inactive' | 'suspended',
  reason?: string  // Optional reason for status change
}
```

**Response:**
```typescript
{
  success: true,
  membership_id: string,
  old_status: string,
  new_status: string,
  updated_at: string
}
```

**SQL Logic:**
```sql
-- Get old status
SELECT status FROM t_group_memberships WHERE id = ${membershipId};

-- Update
UPDATE t_group_memberships
SET 
  status = ${new_status},
  updated_at = CURRENT_TIMESTAMP,
  metadata = jsonb_set(
    COALESCE(metadata, '{}'::jsonb),
    '{status_change_history}',
    COALESCE(metadata->'status_change_history', '[]'::jsonb) || 
    jsonb_build_object(
      'from', ${old_status},
      'to', ${new_status},
      'reason', ${reason},
      'changed_at', CURRENT_TIMESTAMP
    )::jsonb
  )
WHERE id = ${membershipId}
RETURNING id, status, updated_at;

-- Log activity
INSERT INTO t_group_activity_logs (
  group_id, membership_id, activity_type, activity_data
) VALUES (
  ${groupId},
  ${membershipId},
  'status_change',
  jsonb_build_object(
    'old_status', ${old_status},
    'new_status', ${new_status},
    'reason', ${reason}
  )
);
```

**Error Handling:**
- 400: Invalid status value
- 404: Membership not found
- 500: Database error

---

#### Route 3: Get Activity Logs

**Endpoint:** `GET /bbb-admin/activity-logs/:groupId`

**Query Parameters:**
```typescript
{
  activity_type?: string,  // Filter by type
  limit?: number,          // Default: 50, Max: 100
  offset?: number          // Default: 0
}
```

**Response:**
```typescript
{
  success: true,
  logs: [
    {
      id: string,
      activity_type: string,
      tenant_name: string,
      activity_data: object,
      created_at: string
    }
  ],
  pagination: {
    total_count: number,
    limit: number,
    offset: number
  }
}
```

**SQL Query:**
```sql
SELECT 
  al.id,
  al.activity_type,
  tp.business_name as tenant_name,
  al.activity_data,
  al.created_at,
  COUNT(*) OVER() as total_count
FROM t_group_activity_logs al
LEFT JOIN t_tenant_profiles tp ON tp.tenant_id = al.tenant_id
WHERE 
  al.group_id = ${groupId}
  AND (${activity_type} IS NULL OR al.activity_type = ${activity_type})
ORDER BY al.created_at DESC
LIMIT ${limit}
OFFSET ${offset};
```

**Error Handling:**
- 404: Group not found
- 500: Database error

---

### 3.6 Edge Function: `tenant-profile` (Extension)

**File:** `supabase/functions/tenant-profile/index.ts` (EXISTING - MODIFY)

**Changes Required:**

#### Add WhatsApp Fields to Response (GET)

**Before:**
```typescript
return {
  ...profile,
  // existing fields
};
```

**After:**
```typescript
return {
  ...profile,
  business_whatsapp_country_code: profile.business_whatsapp_country_code,
  business_whatsapp: profile.business_whatsapp
};
```

#### Accept WhatsApp Fields in Request (POST/PUT)

**Before:**
```typescript
const profileData = {
  business_name: req.body.business_name,
  // ... existing fields
};
```

**After:**
```typescript
const profileData = {
  business_name: req.body.business_name,
  // ... existing fields
  business_whatsapp_country_code: req.body.business_whatsapp_country_code,
  business_whatsapp: req.body.business_whatsapp
};
```

**No other changes needed.**

---

## 4. API Layer Specifications

### 4.1 File: `src/types/bbb.ts`

**Purpose:** TypeScript interfaces for all BBB data structures

```typescript
// src/types/bbb.ts

// ============================================
// Business Groups
// ============================================
export interface BusinessGroup {
  id: string;
  group_name: string;
  group_type: 'bbb_chapter' | 'tech_forum' | 'network';
  description: string;
  chapter?: string;
  branch?: string;
  member_count: number;
  settings: GroupSettings;
  admin_tenant_id?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface GroupSettings {
  chapter?: string;
  branch?: string;
  city?: string;
  state?: string;
  access?: {
    type: 'password' | 'invite' | 'open';
    user_password?: string;
    admin_password?: string;
  };
  profile_fields?: {
    required: string[];
    optional: string[];
    ai_features: string[];
  };
  search_config?: {
    enabled: boolean;
    search_type: 'vector' | 'hybrid';
    similarity_threshold: number;
    max_results: number;
    cache_enabled: boolean;
    cache_ttl_days: number;
  };
  features?: {
    whatsapp_integration: boolean;
    website_scraping: boolean;
    ai_enhancement: boolean;
    semantic_search: boolean;
    admin_dashboard: boolean;
  };
  whatsapp?: {
    trigger_phrase: string;
    exit_phrase: string;
    bot_enabled: boolean;
  };
  contact?: {
    admin_name: string;
    admin_phone: string;
    support_email: string;
  };
}

// ============================================
// Group Memberships
// ============================================
export interface GroupMembership {
  membership_id: string;
  tenant_id: string;
  group_id: string;
  status: 'draft' | 'pending' | 'active' | 'inactive' | 'suspended';
  joined_at: string;
  profile_data: MemberProfileData;
  embedding?: number[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface MemberProfileData {
  mobile_number?: string;
  member_number?: string;
  generation_method?: 'manual' | 'website';
  short_description?: string;
  ai_enhanced_description?: string;
  website_url?: string;
  website_scraped_data?: {
    title?: string;
    meta_description?: string;
    content_snippets?: string[];
  };
  suggested_keywords?: string[];
  approved_keywords?: string[];
  semantic_tags?: string[];
  last_enhanced_at?: string;
}

export interface MembershipWithProfile extends GroupMembership {
  tenant_profile: {
    business_name: string;
    business_email: string;
    business_phone: string;
    business_whatsapp: string;
    business_whatsapp_country_code: string;
    city: string;
    state_code: string;
    industry_id: string;
    website_url: string;
    logo_url: string;
  };
}

// ============================================
// Semantic Clusters
// ============================================
export interface SemanticCluster {
  id: string;
  membership_id: string;
  primary_term: string;
  related_terms: string[];
  category: string;
  confidence_score: number;
  cluster_embedding?: number[];
  is_active: boolean;
  created_at: string;
}

// ============================================
// Search
// ============================================
export interface SearchRequest {
  group_id: string;
  query: string;
  limit?: number;
  use_cache?: boolean;
}

export interface SearchResult {
  membership_id: string;
  tenant_id: string;
  business_name: string;
  business_email: string;
  mobile_number: string;
  city: string;
  industry: string;
  profile_snippet: string;
  similarity_score: number;
  match_type: 'vector' | 'keyword' | 'semantic';
  logo_url?: string;
}

export interface SearchResponse {
  success: boolean;
  query: string;
  results_count: number;
  from_cache: boolean;
  search_time_ms: number;
  results: SearchResult[];
}

// ============================================
// Admin
// ============================================
export interface AdminStats {
  total_members: number;
  active_members: number;
  pending_members: number;
  inactive_members: number;
  suspended_members: number;
}

export interface ActivityLog {
  id: string;
  activity_type: string;
  tenant_name: string;
  activity_data: Record<string, any>;
  created_at: string;
}

// ============================================
// Form Data Types (UI → API)
// ============================================
export interface ProfileFormData {
  generation_method: 'manual' | 'website';
  short_description?: string;
  website_url?: string;
}

export interface AIEnhancementResponse {
  success: boolean;
  ai_enhanced_description: string;
  suggested_keywords: string[];
  processing_time_ms: number;
}

export interface WebsiteScrapingResponse {
  success: boolean;
  ai_enhanced_description: string;
  suggested_keywords: string[];
  scraped_data: {
    title: string;
    meta_description: string;
    content_snippets: string[];
  };
}

export interface SaveProfileRequest {
  membership_id: string;
  profile_data: {
    generation_method: 'manual' | 'website';
    short_description: string;
    ai_enhanced_description: string;
    approved_keywords: string[];
    website_url?: string;
    website_scraped_data?: any;
  };
  trigger_embedding: boolean;
}
```

---

### 4.2 File: `src/services/bbbService.ts`

**Purpose:** API service layer wrapping all BBB edge functions

```typescript
// src/services/bbbService.ts

import axios, { AxiosError } from 'axios';
import { captureException } from '../utils/sentry';
import { SUPABASE_URL } from '../utils/supabaseConfig';
import type {
  BusinessGroup,
  GroupMembership,
  MembershipWithProfile,
  SearchRequest,
  SearchResponse,
  AIEnhancementResponse,
  WebsiteScrapingResponse,
  SaveProfileRequest,
  SemanticCluster,
  AdminStats,
  ActivityLog
} from '../types/bbb';

// ============================================
// Base Configuration
// ============================================
const BBB_API_BASE = `${SUPABASE_URL}/functions/v1`;

const getHeaders = (authToken: string, tenantId?: string) => ({
  'Authorization': authToken,
  'Content-Type': 'application/json',
  ...(tenantId && { 'x-tenant-id': tenantId })
});

// ============================================
// Service Implementation
// ============================================
export const bbbService = {
  
  // ------------------------------------------
  // GROUPS
  // ------------------------------------------
  
  /**
   * Get all business groups (optionally filter by type)
   */
  async getGroups(
    authToken: string,
    groupType?: 'bbb_chapter' | 'all'
  ): Promise<BusinessGroup[]> {
    try {
      const url = `${BBB_API_BASE}/business-groups${groupType ? `?group_type=${groupType}` : ''}`;
      const response = await axios.get(url, {
        headers: getHeaders(authToken)
      });
      return response.data.groups;
    } catch (error) {
      console.error('Error in getGroups:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'getGroups' }
      });
      throw error;
    }
  },

  /**
   * Get specific group details
   */
  async getGroup(
    authToken: string,
    groupId: string
  ): Promise<BusinessGroup> {
    try {
      const response = await axios.get(`${BBB_API_BASE}/business-groups/${groupId}`, {
        headers: getHeaders(authToken)
      });
      return response.data.group;
    } catch (error) {
      console.error('Error in getGroup:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'getGroup' },
        extra: { groupId }
      });
      throw error;
    }
  },

  /**
   * Verify group access password
   */
  async verifyGroupAccess(
    authToken: string,
    groupId: string,
    password: string,
    accessType: 'user' | 'admin'
  ): Promise<{
    success: boolean;
    access_granted: boolean;
    access_level?: 'user' | 'admin';
    redirect_to?: string;
    error?: string;
  }> {
    try {
      const response = await axios.post(
        `${BBB_API_BASE}/business-groups/verify-access`,
        {
          group_id: groupId,
          password,
          access_type: accessType
        },
        {
          headers: getHeaders(authToken)
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in verifyGroupAccess:', error);
      
      // Don't capture 401 errors (invalid password) in Sentry
      if (axios.isAxiosError(error) && error.response?.status === 401) {
        return {
          success: false,
          access_granted: false,
          error: 'Invalid password'
        };
      }
      
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'verifyGroupAccess' },
        extra: { groupId, accessType }
      });
      throw error;
    }
  },

  // ------------------------------------------
  // MEMBERSHIPS
  // ------------------------------------------

  /**
   * Create new membership (join group)
   */
  async createMembership(
    authToken: string,
    tenantId: string,
    groupId: string,
    profileData?: { mobile_number?: string; member_number?: string }
  ): Promise<GroupMembership> {
    try {
      const response = await axios.post(
        `${BBB_API_BASE}/group-memberships`,
        {
          group_id: groupId,
          profile_data: profileData
        },
        {
          headers: getHeaders(authToken, tenantId)
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in createMembership:', error);
      
      // Handle duplicate membership (409 Conflict)
      if (axios.isAxiosError(error) && error.response?.status === 409) {
        throw new Error('You are already a member of this group');
      }
      
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'createMembership' },
        extra: { tenantId, groupId }
      });
      throw error;
    }
  },

  /**
   * Get membership with tenant profile
   */
  async getMembership(
    authToken: string,
    membershipId: string
  ): Promise<MembershipWithProfile> {
    try {
      const response = await axios.get(
        `${BBB_API_BASE}/group-memberships/${membershipId}`,
        {
          headers: getHeaders(authToken)
        }
      );
      return response.data.membership;
    } catch (error) {
      console.error('Error in getMembership:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'getMembership' },
        extra: { membershipId }
      });
      throw error;
    }
  },

  /**
   * Update membership profile data
   */
  async updateMembership(
    authToken: string,
    membershipId: string,
    updates: {
      profile_data?: Partial<import('../types/bbb').MemberProfileData>;
      status?: 'draft' | 'pending' | 'active' | 'inactive';
    }
  ): Promise<{ membership_id: string; updated_fields: string[]; profile_data: any }> {
    try {
      const response = await axios.put(
        `${BBB_API_BASE}/group-memberships/${membershipId}`,
        updates,
        {
          headers: getHeaders(authToken)
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in updateMembership:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'updateMembership' },
        extra: { membershipId, updates }
      });
      throw error;
    }
  },

  /**
   * Get all memberships for a group (admin)
   */
  async getGroupMemberships(
    authToken: string,
    groupId: string,
    options?: {
      status?: 'all' | 'active' | 'pending' | 'inactive';
      limit?: number;
      offset?: number;
    }
  ): Promise<{
    memberships: any[];
    pagination: { total_count: number; limit: number; offset: number; has_more: boolean };
  }> {
    try {
      const params = new URLSearchParams();
      if (options?.status) params.append('status', options.status);
      if (options?.limit) params.append('limit', options.limit.toString());
      if (options?.offset) params.append('offset', options.offset.toString());

      const response = await axios.get(
        `${BBB_API_BASE}/group-memberships/group/${groupId}?${params.toString()}`,
        {
          headers: getHeaders(authToken)
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in getGroupMemberships:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'getGroupMemberships' },
        extra: { groupId, options }
      });
      throw error;
    }
  },

  /**
   * Delete membership (soft delete)
   */
  async deleteMembership(
    authToken: string,
    membershipId: string
  ): Promise<{ success: boolean; membership_id: string }> {
    try {
      const response = await axios.delete(
        `${BBB_API_BASE}/group-memberships/${membershipId}`,
        {
          headers: getHeaders(authToken)
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in deleteMembership:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'deleteMembership' },
        extra: { membershipId }
      });
      throw error;
    }
  },

  // ------------------------------------------
  // PROFILE OPERATIONS (AI)
  // ------------------------------------------

  /**
   * Enhance profile description with AI
   */
  async enhanceProfile(
    authToken: string,
    membershipId: string,
    shortDescription: string
  ): Promise<AIEnhancementResponse> {
    try {
      const response = await axios.post(
        `${BBB_API_BASE}/bbb-profiles/enhance`,
        {
          membership_id: membershipId,
          short_description: shortDescription
        },
        {
          headers: getHeaders(authToken),
          timeout: 30000 // 30s timeout for AI processing
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in enhanceProfile:', error);
      
      if (axios.isAxiosError(error) && error.code === 'ECONNABORTED') {
        throw new Error('AI enhancement timed out. Please try again.');
      }
      
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'enhanceProfile' },
        extra: { membershipId }
      });
      throw error;
    }
  },

  /**
   * Scrape website and generate profile
   */
  async scrapeWebsite(
    authToken: string,
    membershipId: string,
    websiteUrl: string
  ): Promise<WebsiteScrapingResponse> {
    try {
      const response = await axios.post(
        `${BBB_API_BASE}/bbb-profiles/scrape-website`,
        {
          membership_id: membershipId,
          website_url: websiteUrl
        },
        {
          headers: getHeaders(authToken),
          timeout: 45000 // 45s timeout for scraping + AI
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in scrapeWebsite:', error);
      
      if (axios.isAxiosError(error)) {
        if (error.code === 'ECONNABORTED') {
          throw new Error('Website scraping timed out. Please try again.');
        }
        if (error.response?.status === 422) {
          throw new Error('Unable to access website. Please check the URL.');
        }
      }
      
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'scrapeWebsite' },
        extra: { membershipId, websiteUrl }
      });
      throw error;
    }
  },

  /**
   * Generate semantic clusters
   */
  async generateClusters(
    authToken: string,
    membershipId: string,
    profileText: string,
    keywords: string[]
  ): Promise<{ success: boolean; clusters_generated: number; clusters: SemanticCluster[] }> {
    try {
      const response = await axios.post(
        `${BBB_API_BASE}/bbb-profiles/generate-clusters`,
        {
          membership_id: membershipId,
          profile_text: profileText,
          keywords
        },
        {
          headers: getHeaders(authToken),
          timeout: 30000
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in generateClusters:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'generateClusters' },
        extra: { membershipId }
      });
      throw error;
    }
  },

  /**
   * Save profile and generate embedding
   */
  async saveProfile(
    authToken: string,
    request: SaveProfileRequest
  ): Promise<{ success: boolean; membership_id: string; status: string; embedding_generated: boolean }> {
    try {
      const response = await axios.post(
        `${BBB_API_BASE}/bbb-profiles/save`,
        request,
        {
          headers: getHeaders(authToken),
          timeout: 30000
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in saveProfile:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'saveProfile' },
        extra: { membershipId: request.membership_id }
      });
      throw error;
    }
  },

  // ------------------------------------------
  // SEARCH
  // ------------------------------------------

  /**
   * Search BBB directory
   */
  async search(
    authToken: string,
    request: SearchRequest
  ): Promise<SearchResponse> {
    try {
      const response = await axios.post(
        `${BBB_API_BASE}/bbb-search`,
        request,
        {
          headers: getHeaders(authToken),
          timeout: 15000 // 15s timeout
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in search:', error);
      
      if (axios.isAxiosError(error) && error.code === 'ECONNABORTED') {
        throw new Error('Search timed out. Please try again.');
      }
      
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'search' },
        extra: { request }
      });
      throw error;
    }
  },

  // ------------------------------------------
  // ADMIN
  // ------------------------------------------

  /**
   * Get admin dashboard stats
   */
  async getAdminStats(
    authToken: string,
    groupId: string
  ): Promise<{ stats: AdminStats; recent_activity: ActivityLog[] }> {
    try {
      const response = await axios.get(
        `${BBB_API_BASE}/bbb-admin/stats/${groupId}`,
        {
          headers: getHeaders(authToken)
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in getAdminStats:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'getAdminStats' },
        extra: { groupId }
      });
      throw error;
    }
  },

  /**
   * Update membership status (admin)
   */
  async updateMembershipStatus(
    authToken: string,
    membershipId: string,
    status: 'active' | 'inactive' | 'suspended',
    reason?: string
  ): Promise<{ success: boolean; membership_id: string; old_status: string; new_status: string }> {
    try {
      const response = await axios.put(
        `${BBB_API_BASE}/bbb-admin/memberships/${membershipId}/status`,
        { status, reason },
        {
          headers: getHeaders(authToken)
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in updateMembershipStatus:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'updateMembershipStatus' },
        extra: { membershipId, status }
      });
      throw error;
    }
  },

  /**
   * Get activity logs (admin)
   */
  async getActivityLogs(
    authToken: string,
    groupId: string,
    options?: {
      activity_type?: string;
      limit?: number;
      offset?: number;
    }
  ): Promise<{ logs: ActivityLog[]; pagination: any }> {
    try {
      const params = new URLSearchParams();
      if (options?.activity_type) params.append('activity_type', options.activity_type);
      if (options?.limit) params.append('limit', options.limit.toString());
      if (options?.offset) params.append('offset', options.offset.toString());

      const response = await axios.get(
        `${BBB_API_BASE}/bbb-admin/activity-logs/${groupId}?${params.toString()}`,
        {
          headers: getHeaders(authToken)
        }
      );
      return response.data;
    } catch (error) {
      console.error('Error in getActivityLogs:', error);
      captureException(error instanceof Error ? error : new Error(String(error)), {
        tags: { source: 'bbbService', action: 'getActivityLogs' },
        extra: { groupId, options }
      });
      throw error;
    }
  }
};
```

---

### 4.3 File: `src/services/tenantProfileService.ts` (Extension)

**Changes Required:**

```typescript
// ADD to TenantProfile interface
export interface TenantProfile {
  // ... existing fields ...
  
  // NEW FIELDS
  business_whatsapp_country_code: string | null;
  business_whatsapp: string | null;
  
  // ... rest of existing fields ...
}

// TenantProfileCreate inherits the new fields automatically via Omit
```

**No other changes needed to this file.**

---

## 5. UI Layer Specifications

### 5.1 Component Updates Overview

| Component | File | Action Required | Priority |
|-----------|------|-----------------|----------|
| WhatsAppIntegrationPage | `src/vani/pages/channels/WhatsAppIntegrationPage.tsx` | Replace mock password logic with `bbbService.verifyGroupAccess()` | P0 |
| BBBProfileOnboardingPage | `src/pages/VaNi/channels/BBBProfileOnboardingPage.tsx` | Replace all mock data/delays with real API calls | P0 |
| ProfileEntryForm | `src/components/VaNi/bbb/ProfileEntryForm.tsx` | Connect to `bbbService.createMembership()` | P0 |
| AIEnhancementSection | `src/components/VaNi/bbb/AIEnhancementSection.tsx` | Connect to `bbbService.enhanceProfile()` | P0 |
| WebsiteScrapingForm | `src/components/VaNi/bbb/WebsiteScrapingForm.tsx` | Connect to `bbbService.scrapeWebsite()` | P0 |
| SemanticClustersDisplay | `src/components/VaNi/bbb/SemanticClustersDisplay.tsx` | Connect to `bbbService.generateClusters()` | P0 |
| BBBAdminDashboard | `src/pages/VaNi/channels/BBBAdminDashboard.tsx` | Replace mock data with `bbbService.getAdminStats()` | P1 |
| BBBMemberTable | `src/components/VaNi/bbb/BBBMemberTable.tsx` | Connect to `bbbService.getGroupMemberships()` | P1 |

---

### 5.2 Detailed Component Specifications

#### Component 1: WhatsAppIntegrationPage

**File:** `src/vani/pages/channels/WhatsAppIntegrationPage.tsx`

**Changes Required:**

**BEFORE (Mock Logic):**
```typescript
const handleGroupJoin = async (e: React.FormEvent) => {
  // ... existing code ...
  
  const passwordLower = groupJoinData.password.toLowerCase();

  if (passwordLower === 'admin2025') {
    navigate('/vani/channels/bbb/admin');
  } else if (passwordLower === 'bagyanagar') {
    navigate('/vani/channels/bbb/onboarding', { state: { branch: 'bagyanagar' } });
  } else {
    toast.error('Incorrect password...');
  }
};
```

**AFTER (Real API Call):**
```typescript
import { bbbService } from '../../../services/bbbService';
import { useAuth } from '../../../contexts/AuthContext'; // Assuming you have this

const WhatsAppIntegrationPage: React.FC = () => {
  const { authToken } = useAuth(); // Get auth token
  const [bbbGroupId, setBbbGroupId] = useState<string>(''); // Store group ID
  
  // On component mount, get BBB group ID
  useEffect(() => {
    const fetchBBBGroup = async () => {
      try {
        const groups = await bbbService.getGroups(authToken, 'bbb_chapter');
        const bagyanagar = groups.find(g => g.settings.branch === 'bagyanagar');
        if (bagyanagar) {
          setBbbGroupId(bagyanagar.id);
        }
      } catch (error) {
        console.error('Failed to fetch BBB group:', error);
      }
    };
    fetchBBBGroup();
  }, [authToken]);

  const handleGroupJoin = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!groupJoinData.password.trim()) {
      toast.error('Please enter the password', {
        style: { background: colors.semantic.error, color: '#FFF' }
      });
      return;
    }

    setIsJoiningGroup(true);

    try {
      // Try admin access first
      let result = await bbbService.verifyGroupAccess(
        authToken,
        bbbGroupId,
        groupJoinData.password,
        'admin'
      );

      if (!result.access_granted) {
        // Try user access
        result = await bbbService.verifyGroupAccess(
          authToken,
          bbbGroupId,
          groupJoinData.password,
          'user'
        );
      }

      if (result.access_granted) {
        toast.success(`Password verified! Welcome to BBB Directory`, {
          style: { background: colors.semantic.success, color: '#FFF' },
          duration: 3000
        });

        setGroupJoinData({ phone: '', password: '', name: '' });
        navigate(result.redirect_to || '/vani/channels/bbb/onboarding', {
          state: { branch: 'bagyanagar', groupId: bbbGroupId }
        });
      } else {
        toast.error('Incorrect password. Please contact the group admin for access.', {
          style: { background: colors.semantic.error, color: '#FFF' },
          duration: 4000
        });
      }
    } catch (error) {
      toast.error('Verification failed. Please try again.', {
        style: { background: colors.semantic.error, color: '#FFF' }
      });
    } finally {
      setIsJoiningGroup(false);
    }
  };
  
  // ... rest of component
};
```

**Key Changes:**
1. Import `bbbService` and `useAuth`
2. Fetch BBB group ID on mount
3. Replace hardcoded password check with API call
4. Use API response's `redirect_to` for navigation

---

#### Component 2: BBBProfileOnboardingPage

**File:** `src/pages/VaNi/channels/BBBProfileOnboardingPage.tsx`

**State Management Changes:**

**BEFORE:**
```typescript
const [currentStep, setCurrentStep] = useState<OnboardingStep>('profile_entry');
const [originalDescription, setOriginalDescription] = useState('');
// ... mock state
```

**AFTER:**
```typescript
import { bbbService } from '../../../services/bbbService';
import { tenantProfileService } from '../../../services/tenantProfileService';
import { useAuth } from '../../../contexts/AuthContext';

const BBBProfileOnboardingPage: React.FC = () => {
  const { authToken, tenantId } = useAuth();
  const location = useLocation();
  const groupId = location.state?.groupId; // Passed from WhatsApp page
  
  const [membershipId, setMembershipId] = useState<string>('');
  const [currentTenantProfile, setCurrentTenantProfile] = useState<any>(null);
  const [currentStep, setCurrentStep] = useState<OnboardingStep>('profile_entry');
  
  // ... rest of state
  
  // On mount: Get tenant profile + create membership
  useEffect(() => {
    const initialize = async () => {
      try {
        // 1. Get tenant profile
        const profile = await tenantProfileService.getTenantProfile(authToken, tenantId);
        setCurrentTenantProfile(profile);
        
        // 2. Create membership (if not already exists)
        try {
          const membership = await bbbService.createMembership(
            authToken,
            tenantId,
            groupId,
            {
              mobile_number: profile.business_whatsapp || profile.business_phone
            }
          );
          setMembershipId(membership.membership_id);
        } catch (error: any) {
          if (error.message?.includes('already a member')) {
            // Fetch existing membership
            // TODO: Add endpoint to get membership by tenant + group
            console.log('Already a member');
          }
        }
      } catch (error) {
        console.error('Initialization failed:', error);
        toast.error('Failed to load profile. Please try again.');
      }
    };
    
    if (authToken && tenantId && groupId) {
      initialize();
    }
  }, [authToken, tenantId, groupId]);
  
  // ... rest of component
};
```

**Replace Mock AI Enhancement:**

**BEFORE:**
```typescript
const handleEnhanceWithAI = async (description: string) => {
  setIsEnhancing(true);
  await simulateDelay(2000); // MOCK
  const enhanced = `Mock enhanced text...`;
  setEnhancedDescription(enhanced);
  setIsEnhancing(false);
};
```

**AFTER:**
```typescript
const handleEnhanceWithAI = async (description: string) => {
  setIsEnhancing(true);
  setOriginalDescription(description);

  try {
    const result = await bbbService.enhanceProfile(
      authToken,
      membershipId,
      description
    );

    setEnhancedDescription(result.ai_enhanced_description);
    setKeywords(result.suggested_keywords);
    setCurrentStep('ai_enhanced');

    toast.success('AI enhancement complete!', {
      style: { background: colors.semantic.success, color: '#FFF' }
    });
  } catch (error: any) {
    toast.error(error.message || 'Enhancement failed. Please try again.', {
      style: { background: colors.semantic.error, color: '#FFF' }
    });
  } finally {
    setIsEnhancing(false);
  }
};
```

**Replace Mock Website Scraping:**

```typescript
const handleFormSubmit = async (data: ProfileFormData) => {
  if (data.generation_method === 'website' && data.website_url) {
    setIsScrapingWebsite(true);
    setWebsiteUrl(data.website_url);

    try {
      const result = await bbbService.scrapeWebsite(
        authToken,
        membershipId,
        data.website_url
      );

      setEnhancedDescription(result.ai_enhanced_description);
      setKeywords(result.suggested_keywords);
      setCurrentStep('website_scraped');

      toast.success('Website analyzed successfully!', {
        style: { background: colors.semantic.success, color: '#FFF' }
      });
    } catch (error: any) {
      toast.error(error.message || 'Website scraping failed.', {
        style: { background: colors.semantic.error, color: '#FFF' }
      });
    } finally {
      setIsScrapingWebsite(false);
    }
  } else if (data.generation_method === 'manual' && data.short_description) {
    // User clicked "Save my profile" without AI enhancement
    await handleSaveProfile(data.short_description);
  }
};
```

**Replace Mock Save Profile:**

```typescript
const handleSaveProfile = async (description: string) => {
  setIsSavingProfile(true);

  try {
    const result = await bbbService.saveProfile(authToken, {
      membership_id: membershipId,
      profile_data: {
        generation_method: websiteUrl ? 'website' : 'manual',
        short_description: originalDescription || description,
        ai_enhanced_description: enhancedDescription || description,
        approved_keywords: keywords,
        website_url: websiteUrl || undefined
      },
      trigger_embedding: true // Generate vector embedding
    });

    if (keywords.length === 0) {
      // Set default keywords
      setKeywords([
        currentTenantProfile.industry_id || 'Business',
        currentTenantProfile.city || 'Hyderabad',
        'Professional'
      ]);
    }

    setCurrentStep('semantic_clusters');

    toast.success('Profile saved! Generating semantic clusters...', {
      style: { background: colors.semantic.success, color: '#FFF' }
    });

    // Auto-generate clusters
    setTimeout(() => {
      handleGenerateClusters();
    }, 500);
  } catch (error: any) {
    toast.error(error.message || 'Profile save failed.', {
      style: { background: colors.semantic.error, color: '#FFF' }
    });
    setIsSavingProfile(false);
  }
};
```

**Replace Mock Cluster Generation:**

```typescript
const handleGenerateClusters = async () => {
  setIsGeneratingClusters(true);

  try {
    const result = await bbbService.generateClusters(
      authToken,
      membershipId,
      enhancedDescription,
      keywords
    );

    setGeneratedClusters(result.clusters);

    toast.success('Semantic clusters generated!', {
      style: { background: colors.semantic.success, color: '#FFF' }
    });

    // Proceed to success
    setTimeout(() => {
      setCurrentStep('success');
    }, 1500);
  } catch (error: any) {
    toast.error(error.message || 'Cluster generation failed.', {
      style: { background: colors.semantic.error, color: '#FFF' }
    });
  } finally {
    setIsGeneratingClusters(false);
  }
};
```

**Key Changes:**
1. Remove all `simulateDelay()` calls
2. Replace mock data with real API calls
3. Use actual `membershipId` from state
4. Handle errors properly with toast notifications
5. Pass `authToken` to all service calls

---

#### Component 3: BBBAdminDashboard

**File:** `src/pages/VaNi/channels/BBBAdminDashboard.tsx`

**Replace Mock Data:**

**BEFORE:**
```typescript
import { mockMarketProfiles, mockTenantProfiles, mockAdminStats } from '../../../utils/fakejson/bbbMockData';
```

**AFTER:**
```typescript
import { bbbService } from '../../../services/bbbService';
import { useAuth } from '../../../contexts/AuthContext';

const BBBAdminDashboard: React.FC = () => {
  const { authToken } = useAuth();
  const [groupId] = useState<string>('YOUR_GROUP_ID'); // Get from context or route
  const [stats, setStats] = useState<any>(null);
  const [members, setMembers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsData, membersData] = await Promise.all([
          bbbService.getAdminStats(authToken, groupId),
          bbbService.getGroupMemberships(authToken, groupId, { status: 'all', limit: 50 })
        ]);

        setStats(statsData.stats);
        setMembers(membersData.memberships);
      } catch (error) {
        console.error('Failed to load admin data:', error);
        toast.error('Failed to load dashboard data');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [authToken, groupId]);

  if (loading) {
    return <div>Loading...</div>;
  }

  // Use stats and members from state instead of mockAdminStats
  // ... rest of component
};
```

---

### 5.3 New Hook: `useBBBGroup`

**File:** `src/hooks/useBBBGroup.ts` (NEW FILE)

**Purpose:** Reusable hook to manage BBB group ID across components

```typescript
// src/hooks/useBBBGroup.ts

import { useState, useEffect } from 'react';
import { bbbService } from '../services/bbbService';
import { useAuth } from '../contexts/AuthContext';

export const useBBBGroup = (branch: string = 'bagyanagar') => {
  const { authToken } = useAuth();
  const [groupId, setGroupId] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchGroup = async () => {
      try {
        const groups = await bbbService.getGroups(authToken, 'bbb_chapter');
        const group = groups.find(g => g.settings.branch === branch);
        
        if (group) {
          setGroupId(group.id);
        } else {
          setError('BBB group not found');
        }
      } catch (err) {
        setError('Failed to fetch BBB group');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    if (authToken) {
      fetchGroup();
    }
  }, [authToken, branch]);

  return { groupId, loading, error };
};
```

**Usage in Components:**
```typescript
const { groupId, loading } = useBBBGroup('bagyanagar');

if (loading) return <Spinner />;
// Use groupId for API calls
```

---

## 6. Data Flow Diagrams

### 6.1 Profile Onboarding Flow

```
USER ACTION                     UI LAYER                    API LAYER                   EDGE LAYER                  n8n                     DATABASE
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

1. Enter password "bagyanagar"
                           ─────────►  bbbService.verifyGroupAccess() ───► business-groups/verify-access ───► Check settings.access.user_password
                                                                                                                          │
                                                                                                                          ▼
                           ◄─────────  { access_granted: true, redirect_to: '/onboarding' }  ◄──────────────── Return success
                                  │
                                  ▼
2. Navigate to onboarding
                           ─────────►  bbbService.createMembership()  ───► group-memberships (POST)  ────────► INSERT INTO t_group_memberships
                                                                                                                          │
                           ◄─────────  { membership_id: "uuid" }  ◄──────────────────────────────────────────────── RETURNING id

3. Enter short description
   "Software development company"
                           ─────────►  bbbService.enhanceProfile()  ───► bbb-profiles/enhance  ───► POST to n8n/profile-enhance ───► OpenAI API
                                                                                                            │                              │
                                                                                                            │                              ▼
                                                                                                            │                   Generate 6-8 lines + keywords
                                                                                                            ◄──────────────────────────────┘
                           ◄─────────  { ai_enhanced_description, suggested_keywords }  ◄─────┘

4. Save profile
                           ─────────►  bbbService.saveProfile()  ───► bbb-profiles/save  ───► UPDATE t_group_memberships SET profile_data
                                                                                          │
                                                                                          └──► POST to n8n/profile-ingest ───► OpenAI Embeddings API
                                                                                                                                        │
                                                                                                                                        ▼
                                                                                                         UPDATE t_group_memberships SET embedding

5. Generate clusters
                           ─────────►  bbbService.generateClusters()  ───► bbb-profiles/generate-clusters  ───► POST to n8n/generate-clusters ───► OpenAI API
                                                                                                                          │                              │
                                                                                                                          │                              ▼
                                                                                                                          │                    Generate semantic clusters
                                                                                                                          ◄──────────────────────────────┘
                                                                                                                          │
                                                                                                                          ▼
                                                                                                         INSERT INTO t_semantic_clusters (multiple rows)

6. Success → Navigate to dashboard
```

---

### 6.2 Search Flow (with Caching)

```
USER ACTION                     UI LAYER                    API LAYER                   EDGE LAYER                  n8n                     DATABASE
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

1. User searches "networking equipment"

                           ─────────►  bbbService.search()  ───► bbb-search (POST)  ───┐
                                                                                         │
                                                                                         ▼
                                                                          Check t_search_query_cache
                                                                          WHERE query_normalized = 'networking equipment'
                                                                            AND expires_at > NOW()
                                                                                         │
                                                               ┌─────────────────────────┴──────────────────────────┐
                                                               │                                                    │
                                                          CACHE HIT                                            CACHE MISS
                                                               │                                                    │
                                                               ▼                                                    ▼
                                                    UPDATE hit_count + 1                            POST to n8n/search webhook
                                                               │                                                    │
                                                               │                                                    ▼
                                                               │                                         Generate embedding via OpenAI
                                                               │                                                    │
                                                               │                                                    ▼
                                                               │                                    Call search_group_members() function
                                                               │                                                    │
                                                               │                                                    ▼
                                                               │                                    SELECT with vector similarity + keyword matching
                                                               │                                                    │
                                                               │                                                    ▼
                                                               │                                    INSERT INTO t_search_query_cache
                                                               │                                                    │
                                                               └────────────────────┬───────────────────────────────┘
                                                                                    │
                           ◄─────────────────────────────────────────────────────  ▼
                                                { results[], from_cache: true/false }
```

---

## 7. Error Handling Standards

### 7.1 HTTP Status Codes

| Code | Meaning | When to Use | Frontend Handling |
|------|---------|-------------|-------------------|
| 200 | OK | Successful GET/POST/PUT | Display success toast |
| 201 | Created | Resource created (membership, profile) | Navigate to next step |
| 400 | Bad Request | Missing required fields, invalid input | Show validation error |
| 401 | Unauthorized | Invalid password, expired token | Redirect to login |
| 404 | Not Found | Group/membership not found | Show "not found" message |
| 409 | Conflict | Duplicate membership | Inform user already member |
| 422 | Unprocessable | Website unreachable, invalid URL | Show specific error |
| 429 | Too Many Requests | Rate limit exceeded | Ask user to wait |
| 500 | Server Error | Database error, n8n failure | Generic error + log to Sentry |
| 504 | Gateway Timeout | n8n webhook timeout | Show timeout message, retry option |

### 7.2 Error Response Format

**All edge functions must return errors in this format:**

```typescript
{
  success: false,
  error: {
    code: string,           // Machine-readable code (e.g., "INVALID_PASSWORD")
    message: string,        // Human-readable message
    details?: any,          // Optional additional context
    timestamp: string       // ISO timestamp
  }
}
```

**Example:**
```json
{
  "success": false,
  "error": {
    "code": "MEMBERSHIP_EXISTS",
    "message": "You are already a member of this group",
    "details": { "existing_membership_id": "..." },
    "timestamp": "2024-11-19T10:30:00Z"
  }
}
```

### 7.3 Frontend Error Handling Pattern

```typescript
try {
  const result = await bbbService.someMethod(...);
  // Success handling
  toast.success('Operation successful!');
} catch (error) {
  if (axios.isAxiosError(error)) {
    const status = error.response?.status;
    const errorData = error.response?.data?.error;
    
    if (status === 401) {
      toast.error('Session expired. Please log in again.');
      navigate('/login');
    } else if (status === 409) {
      toast.error(errorData?.message || 'Duplicate entry');
    } else if (status === 504) {
      toast.error('Operation timed out. Please try again.');
    } else {
      toast.error(errorData?.message || 'An error occurred');
    }
    
    // Log to Sentry
    captureException(error, {
      tags: { source: 'bbb', action: 'someMethod' },
      extra: { status, errorData }
    });
  } else {
    toast.error('An unexpected error occurred');
    captureException(error);
  }
}
```

---

## 8. Testing Requirements

### 8.1 Edge Function Testing

**Each edge function must have:**
1. Unit tests for database queries
2. Integration tests with n8n webhooks
3. Error handling tests

**Test Coverage Targets:**
- Business logic: 80%
- Error paths: 100%
- Happy path: 100%

### 8.2 API Layer Testing

**Service layer must have:**
1. Mock API response tests
2. Error handling tests
3. Timeout tests

### 8.3 UI Layer Testing

**Component tests must cover:**
1. Form validation
2. Loading states
3. Error states
4. Success states
5. Navigation flows

### 8.4 End-to-End Testing Scenarios

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| **Happy Path: Manual Profile** | 1. Enter password<br>2. Create membership<br>3. Enter description<br>4. AI enhance<br>5. Save profile<br>6. Generate clusters | Profile created with status='active', embedding generated, clusters stored |
| **Happy Path: Website Profile** | 1. Enter password<br>2. Create membership<br>3. Enter URL<br>4. Scrape website<br>5. Save profile<br>6. Generate clusters | Profile created from website, embedding generated |
| **Error: Invalid Password** | 1. Enter wrong password<br>2. Submit | Show error: "Invalid password" |
| **Error: Duplicate Membership** | 1. Join group twice | Show error: "Already a member" |
| **Error: Timeout** | 1. AI enhancement takes >30s | Show error: "Timed out, please retry" |
| **Search: Cache Hit** | 1. Search "IT services"<br>2. Search same query again | 2nd search returns from_cache=true, <100ms |
| **Search: Cache Miss** | 1. Search unique query | Results from vector search, <2s |
| **Admin: View Members** | 1. Access admin dashboard | Show all members with stats |
| **Admin: Update Status** | 1. Change member status to "inactive" | Status updated, activity logged |

---

## 9. Implementation Checklist

### Phase 1: Edge Functions (Backend)
- [ ] Create `business-groups` edge function (3 routes)
- [ ] Create `group-memberships` edge function (5 routes)
- [ ] Create `bbb-profiles` edge function (4 routes)
- [ ] Create `bbb-search` edge function (1 route)
- [ ] Create `bbb-admin` edge function (3 routes)
- [ ] Update `tenant-profile` edge function (add WhatsApp fields)
- [ ] Test all endpoints with Postman/Insomnia

### Phase 2: API Services (Frontend Services)
- [ ] Create `src/types/bbb.ts` with all interfaces
- [ ] Create `src/services/bbbService.ts` with all methods
- [ ] Update `src/services/tenantProfileService.ts` interface
- [ ] Create `src/hooks/useBBBGroup.ts` helper hook
- [ ] Test services with mock edge functions

### Phase 3: UI Integration
- [ ] Update `WhatsAppIntegrationPage` (password verification)
- [ ] Update `BBBProfileOnboardingPage` (replace all mocks)
- [ ] Update `ProfileEntryForm` (membership creation)
- [ ] Update `AIEnhancementSection` (AI enhancement)
- [ ] Update `WebsiteScrapingForm` (website scraping)
- [ ] Update `SemanticClustersDisplay` (cluster generation)
- [ ] Update `BBBAdminDashboard` (admin stats)
- [ ] Update `BBBMemberTable` (member list)

### Phase 4: Testing
- [ ] Test onboarding flow (manual method)
- [ ] Test onboarding flow (website method)
- [ ] Test search with caching
- [ ] Test admin dashboard
- [ ] Test error scenarios
- [ ] Load test with 10+ profiles

### Phase 5: Deployment
- [ ] Deploy all edge functions to Supabase
- [ ] Update frontend environment variables
- [ ] Deploy frontend
- [ ] Verify n8n webhooks are accessible
- [ ] Load initial BBB members

---

## 10. Environment Variables

### Required Environment Variables

```env
# Supabase (Frontend)
VITE_SUPABASE_URL=https://[PROJECT_REF].supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...

# n8n Webhooks (Edge Functions)
N8N_ENHANCE_URL=https://n8n.srv1017206.hstgr.cloud/webhook-test/profile-enhance
N8N_SCRAPE_URL=https://n8n.srv1017206.hstgr.cloud/webhook-test/website-scrape
N8N_CLUSTERS_URL=https://n8n.srv1017206.hstgr.cloud/webhook-test/generate-clusters
N8N_EMBED_URL=https://n8n.srv1017206.hstgr.cloud/webhook-test/profile-ingest
N8N_SEARCH_URL=https://n8n.srv1017206.hstgr.cloud/webhook-test/search

# Supabase (Edge Functions)
SUPABASE_URL=https://[PROJECT_REF].supabase.co
SUPABASE_SERVICE_KEY=eyJ... (service role key for RLS bypass)

# OpenAI (via n8n - not directly in edge functions)
# Managed by n8n workflows
```

---

## 11. Success Criteria

**The BBB integration is complete when:**

✅ User can join BBB group with password  
✅ User can create profile via manual entry + AI enhancement  
✅ User can create profile via website scraping  
✅ Profile is saved with vector embedding  
✅ Semantic clusters are generated  
✅ Search returns relevant results in <2s  
✅ Cache hit rate >70% after 100 searches  
✅ Admin can view dashboard with stats  
✅ Admin can manage member status  
✅ All error scenarios handled gracefully  
✅ No console errors in production  

---

**END OF SPECIFICATION**

**Next Step:** Share this spec with "claude developer" to build the code. Each section is designed to be self-contained and implementable independently.