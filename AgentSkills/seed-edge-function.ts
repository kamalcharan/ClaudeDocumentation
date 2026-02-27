import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * ContractNest Master Data Seeding Edge Function
 * 
 * Automatically seeds industry-specific master data when a tenant
 * selects their industries during onboarding.
 * 
 * POST /functions/v1/seed-master-data
 * Authorization: Bearer <jwt>
 * 
 * Body:
 * {
 *   tenant_id: string,
 *   target_industries: string[],
 *   nomenclatures?: string[],
 *   user_id: string,
 *   options?: { skip_categories, skip_catalog, skip_blocks, skip_events, dry_run }
 * }
 */

interface SeedRequest {
  tenant_id: string;
  target_industries: string[];
  nomenclatures?: string[];
  user_id: string;
  options?: {
    skip_categories?: boolean;
    skip_catalog?: boolean;
    skip_blocks?: boolean;
    skip_events?: boolean;
    dry_run?: boolean;
  };
}

interface SeedResult {
  category_masters: number;
  category_details: number;
  catalog_industries: number;
  catalog_categories: number;
  resource_templates: number;
  contract_blocks: number;
  event_statuses: number;
}

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, content-type, x-client-info, apikey",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const body: SeedRequest = await req.json();
    const { tenant_id, target_industries, nomenclatures, user_id, options } = body;

    // Validate required fields
    if (!tenant_id || !target_industries?.length || !user_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: tenant_id, target_industries, user_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Create Supabase client with service role for admin operations
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    );

    // Verify tenant exists
    const { data: tenant, error: tenantError } = await supabase
      .from("t_tenants")
      .select("id, name, status")
      .eq("id", tenant_id)
      .single();

    if (tenantError || !tenant) {
      return new Response(
        JSON.stringify({ error: `Tenant not found: ${tenant_id}` }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    const result: SeedResult = {
      category_masters: 0,
      category_details: 0,
      catalog_industries: 0,
      catalog_categories: 0,
      resource_templates: 0,
      contract_blocks: 0,
      event_statuses: 0,
    };
    const errors: string[] = [];

    // === STEP A: Foundation — Category Master & Details ===
    if (!options?.skip_categories) {
      try {
        // A1: Copy category masters
        const { data: catMasters } = await supabase.rpc("seed_category_masters", {
          p_tenant_id: tenant_id,
        });
        result.category_masters = catMasters?.count ?? 0;

        // A2: Copy category details
        const { data: catDetails } = await supabase.rpc("seed_category_details", {
          p_tenant_id: tenant_id,
        });
        result.category_details = catDetails?.count ?? 0;
      } catch (e) {
        errors.push(`Category seeding failed: ${(e as Error).message}`);
      }
    }

    // === STEP B: Catalog — Industries, Categories, Resources ===
    if (!options?.skip_catalog) {
      try {
        // B1: Record served industries
        for (const industryId of target_industries) {
          await supabase
            .from("t_tenant_served_industries")
            .upsert(
              { tenant_id, industry_id: industryId, added_by: user_id },
              { onConflict: "tenant_id,industry_id", ignoreDuplicates: true }
            );
        }

        // B2: Create tenant catalog industries
        const { data: industries } = await supabase
          .from("m_catalog_industries")
          .select("*")
          .in("id", target_industries)
          .eq("is_active", true);

        if (industries) {
          for (const ind of industries) {
            const { error } = await supabase.from("t_catalog_industries").upsert(
              {
                tenant_id,
                industry_code: ind.id,
                name: ind.name,
                description: ind.description,
                icon: ind.icon,
                common_pricing_rules: ind.common_pricing_rules,
                compliance_requirements: ind.compliance_requirements,
                master_industry_id: ind.id,
                is_custom: false,
                is_active: true,
              },
              { onConflict: "tenant_id,industry_code", ignoreDuplicates: true }
            );
            if (!error) result.catalog_industries++;
          }
        }

        // B3: Seed catalog categories from industry map
        const { data: categoryMaps } = await supabase
          .from("m_catalog_category_industry_map")
          .select("category_id, industry_id, display_name, display_order, customizations")
          .in("industry_id", target_industries)
          .eq("is_active", true);

        if (categoryMaps) {
          const categoryIds = [...new Set(categoryMaps.map((m) => m.category_id))];
          const { data: masterCategories } = await supabase
            .from("m_catalog_categories")
            .select("*")
            .in("id", categoryIds)
            .eq("is_active", true);

          const masterMap = new Map((masterCategories ?? []).map((c) => [c.id, c]));

          // Get tenant's catalog industry IDs
          const { data: tenantIndustries } = await supabase
            .from("t_catalog_industries")
            .select("id, industry_code")
            .eq("tenant_id", tenant_id);

          const industryIdMap = new Map((tenantIndustries ?? []).map((i) => [i.industry_code, i.id]));

          for (const cm of categoryMaps) {
            const mc = masterMap.get(cm.category_id);
            const tenantIndustryId = industryIdMap.get(cm.industry_id);
            if (!mc || !tenantIndustryId) continue;

            const { error } = await supabase.from("t_catalog_categories").upsert(
              {
                tenant_id,
                industry_id: tenantIndustryId,
                category_code: mc.id,
                name: cm.display_name || mc.name,
                description: mc.description,
                icon: mc.icon,
                default_pricing_model: mc.default_pricing_model,
                suggested_duration: mc.suggested_duration,
                common_variants: mc.common_variants,
                pricing_rule_templates: mc.pricing_rule_templates,
                master_category_id: mc.id,
                is_custom: false,
                is_active: true,
                sort_order: cm.display_order,
              },
              { onConflict: "tenant_id,category_code,industry_id", ignoreDuplicates: true }
            );
            if (!error) result.catalog_categories++;
          }
        }

        // B4: Seed resource templates
        const { data: resourceTemplates } = await supabase
          .from("m_catalog_resource_templates")
          .select("*")
          .in("industry_id", target_industries)
          .eq("is_active", true);

        if (resourceTemplates) {
          for (const rt of resourceTemplates) {
            const { error } = await supabase.from("t_category_resources_master").upsert(
              {
                tenant_id,
                resource_type_id: rt.resource_type_id,
                name: rt.name,
                display_name: rt.name,
                description: rt.description,
                sub_category: rt.sub_category,
                tags: {
                  default_attributes: rt.default_attributes,
                  pricing_guidance: rt.pricing_guidance,
                  source: "seed",
                  source_industry: rt.industry_id,
                },
                is_active: true,
                is_live: true,
              },
              { onConflict: "tenant_id,name,resource_type_id", ignoreDuplicates: true }
            );
            if (!error) result.resource_templates++;
          }
        }
      } catch (e) {
        errors.push(`Catalog seeding failed: ${(e as Error).message}`);
      }
    }

    // === STEP C: Contract Blocks ===
    if (!options?.skip_blocks && nomenclatures?.length) {
      try {
        // Get tenant's block type IDs
        const { data: blockTypes } = await supabase
          .from("t_category_details")
          .select("id, sub_cat_name")
          .eq("tenant_id", tenant_id)
          .in("sub_cat_name", ["service", "spare", "billing", "text", "checklist", "document"]);

        const blockTypeMap = new Map((blockTypes ?? []).map((bt) => [bt.sub_cat_name, bt.id]));

        // Get pricing mode and price type IDs
        const { data: pricingDetails } = await supabase
          .from("t_category_details")
          .select("id, sub_cat_name")
          .eq("tenant_id", tenant_id)
          .in("sub_cat_name", [
            "independent", "resource_based", "variant_based",
            "per_session", "per_hour", "per_day", "per_unit", "fixed",
          ]);

        const pricingMap = new Map((pricingDetails ?? []).map((p) => [p.sub_cat_name, p.id]));

        for (const nom of nomenclatures) {
          const blocks = generateBlocksForNomenclature(nom, blockTypeMap, pricingMap);
          for (const block of blocks) {
            const { error } = await supabase.from("cat_blocks").insert({
              tenant_id,
              ...block,
              is_seed: true,
              is_live: true,
              is_active: true,
            });
            if (!error) result.contract_blocks++;
          }
        }
      } catch (e) {
        errors.push(`Block seeding failed: ${(e as Error).message}`);
      }
    }

    // === STEP D: Event Status Config ===
    if (!options?.skip_events) {
      try {
        const eventTypes = getEventTypesForNomenclatures(nomenclatures ?? ["amc"]);
        for (const et of eventTypes) {
          for (const status of et.statuses) {
            const { error } = await supabase.from("m_event_status_config").insert({
              tenant_id,
              event_type: et.event_type,
              ...status,
              is_active: true,
              source: "seed",
            });
            if (!error) result.event_statuses++;
          }
        }
      } catch (e) {
        errors.push(`Event config seeding failed: ${(e as Error).message}`);
      }
    }

    return new Response(
      JSON.stringify({
        success: errors.length === 0,
        tenant_id,
        tenant_name: tenant.name,
        seeded: result,
        errors: errors.length > 0 ? errors : undefined,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: `Unexpected error: ${(e as Error).message}` }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

// ===== Helper Functions =====

function generateBlocksForNomenclature(
  nomenclature: string,
  blockTypeMap: Map<string, string>,
  pricingMap: Map<string, string>
): Record<string, unknown>[] {
  const blocks: Record<string, unknown>[] = [];
  const serviceTypeId = blockTypeMap.get("service");
  const spareTypeId = blockTypeMap.get("spare");
  const billingTypeId = blockTypeMap.get("billing");
  const textTypeId = blockTypeMap.get("text");
  const checklistTypeId = blockTypeMap.get("checklist");

  switch (nomenclature) {
    case "amc":
      blocks.push(
        {
          block_type_id: serviceTypeId,
          name: "Preventive Maintenance",
          display_name: "Preventive Maintenance Visits",
          description: "Scheduled preventive maintenance visits as per AMC terms",
          category: "core",
          config: { frequency: "quarterly", visits_per_year: 4 },
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("per_session"),
          sequence_no: 1,
        },
        {
          block_type_id: serviceTypeId,
          name: "Breakdown Support",
          display_name: "Breakdown Support",
          description: "On-call breakdown response within SLA",
          category: "core",
          config: { response_sla_hours: 4, included_visits: "unlimited" },
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("fixed"),
          sequence_no: 2,
        },
        {
          block_type_id: spareTypeId,
          name: "Spare Parts",
          display_name: "Spare Parts Coverage",
          description: "Parts replacement policy under AMC",
          category: "core",
          config: { coverage: "excluded", discount_percent: 15 },
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("per_unit"),
          sequence_no: 3,
        },
        {
          block_type_id: billingTypeId,
          name: "AMC Billing",
          display_name: "Payment Terms",
          description: "Annual contract billing structure",
          category: "commercial",
          config: { cycle: "quarterly_advance", payment_terms_days: 15 },
          sequence_no: 4,
        },
        {
          block_type_id: textTypeId,
          name: "AMC Scope",
          display_name: "Scope of Work",
          description: "Detailed scope of maintenance activities covered under AMC",
          category: "content",
          config: { content_type: "scope" },
          sequence_no: 5,
        },
        {
          block_type_id: textTypeId,
          name: "AMC Exclusions",
          display_name: "Exclusions",
          description: "Activities and items not covered under this AMC",
          category: "content",
          config: { content_type: "exclusions" },
          sequence_no: 6,
        },
        {
          block_type_id: checklistTypeId,
          name: "Equipment Checklist",
          display_name: "Equipment Covered",
          description: "List of equipment covered under this AMC with serial numbers",
          category: "content",
          config: { requires_evidence: true },
          sequence_no: 7,
        }
      );
      break;

    case "cmc":
      blocks.push(
        {
          block_type_id: serviceTypeId,
          name: "Comprehensive Maintenance",
          display_name: "Comprehensive Maintenance",
          description: "All-inclusive maintenance — labor, parts, and consumables",
          category: "core",
          config: { frequency: "quarterly", visits_per_year: 4, includes_parts: true, includes_consumables: true },
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("fixed"),
          sequence_no: 1,
        },
        {
          block_type_id: serviceTypeId,
          name: "Unlimited Breakdown",
          display_name: "Unlimited Breakdown Support",
          description: "Unlimited breakdown calls with guaranteed response SLA",
          category: "core",
          config: { response_sla_hours: 2, resolution_sla_hours: 8, unlimited: true },
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("fixed"),
          sequence_no: 2,
        },
        {
          block_type_id: spareTypeId,
          name: "All Parts Included",
          display_name: "Parts & Consumables",
          description: "All replacement parts and consumables included at zero extra cost",
          category: "core",
          config: { coverage: "full", max_part_value: null },
          sequence_no: 3,
        },
        {
          block_type_id: billingTypeId,
          name: "CMC Billing",
          display_name: "Payment Terms",
          description: "Fixed billing for comprehensive coverage",
          category: "commercial",
          config: { cycle: "monthly_fixed", payment_terms_days: 10 },
          sequence_no: 4,
        },
        {
          block_type_id: textTypeId,
          name: "CMC Scope",
          display_name: "Comprehensive Scope",
          description: "Complete scope including parts, labor, and consumables",
          category: "content",
          config: { content_type: "scope" },
          sequence_no: 5,
        },
        {
          block_type_id: checklistTypeId,
          name: "Equipment Checklist",
          display_name: "Equipment Covered",
          description: "Full equipment registry with condition assessment",
          category: "content",
          config: { requires_evidence: true, requires_photos: true },
          sequence_no: 6,
        }
      );
      break;

    case "fmc":
      blocks.push(
        {
          block_type_id: serviceTypeId,
          name: "Housekeeping",
          display_name: "Housekeeping Services",
          description: "Daily housekeeping, cleaning, and waste management",
          category: "core",
          config: { frequency: "daily", shift_coverage: "8hrs" },
          pricing_mode_id: pricingMap.get("resource_based"),
          price_type_id: pricingMap.get("per_day"),
          sequence_no: 1,
        },
        {
          block_type_id: serviceTypeId,
          name: "Technical Maintenance",
          display_name: "Technical Maintenance",
          description: "HVAC, electrical, plumbing, and general building maintenance",
          category: "core",
          config: { frequency: "daily_plus_scheduled", preventive_schedule: "monthly" },
          pricing_mode_id: pricingMap.get("resource_based"),
          price_type_id: pricingMap.get("per_day"),
          sequence_no: 2,
        },
        {
          block_type_id: serviceTypeId,
          name: "Security",
          display_name: "Security Services",
          description: "24x7 security deployment with access control management",
          category: "core",
          config: { coverage: "24x7", shift_pattern: "8hr_3shifts" },
          pricing_mode_id: pricingMap.get("resource_based"),
          price_type_id: pricingMap.get("per_day"),
          sequence_no: 3,
        },
        {
          block_type_id: serviceTypeId,
          name: "Landscaping",
          display_name: "Landscaping & Gardening",
          description: "Garden maintenance, landscaping, and green area upkeep",
          category: "core",
          config: { frequency: "weekly" },
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("fixed"),
          sequence_no: 4,
        },
        {
          block_type_id: serviceTypeId,
          name: "Pest Control",
          display_name: "Pest Control",
          description: "Quarterly pest control and fumigation services",
          category: "core",
          config: { frequency: "quarterly" },
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("per_session"),
          sequence_no: 5,
        },
        {
          block_type_id: billingTypeId,
          name: "FMC Billing",
          display_name: "Payment Terms",
          description: "Monthly fixed fee with variable component for ad-hoc services",
          category: "commercial",
          config: { cycle: "monthly_fixed_plus_variable", payment_terms_days: 15 },
          sequence_no: 6,
        },
        {
          block_type_id: textTypeId,
          name: "Deployment Plan",
          display_name: "Staff Deployment Plan",
          description: "Detailed manpower deployment including roles, shifts, and headcount",
          category: "content",
          config: { content_type: "deployment" },
          sequence_no: 7,
        },
        {
          block_type_id: textTypeId,
          name: "SLA Matrix",
          display_name: "SLA Matrix",
          description: "Service level targets for each service area",
          category: "content",
          config: { content_type: "sla" },
          sequence_no: 8,
        },
        {
          block_type_id: checklistTypeId,
          name: "Daily Inspection",
          display_name: "Daily Inspection Checklist",
          description: "Daily facility inspection items with evidence capture",
          category: "content",
          config: { requires_evidence: true, frequency: "daily" },
          sequence_no: 9,
        }
      );
      break;

    case "manpower":
      blocks.push(
        {
          block_type_id: serviceTypeId,
          name: "Staff Deployment",
          display_name: "Staff Deployment",
          description: "Dedicated manpower deployment — roles, count, and shifts",
          category: "core",
          config: { deployment_type: "dedicated" },
          pricing_mode_id: pricingMap.get("resource_based"),
          price_type_id: pricingMap.get("per_day"),
          sequence_no: 1,
        },
        {
          block_type_id: serviceTypeId,
          name: "Replacement Provision",
          display_name: "Replacement / Relief Staff",
          description: "Substitute staff during leave, absenteeism, or attrition",
          category: "core",
          config: { replacement_sla_hours: 24 },
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("fixed"),
          sequence_no: 2,
        },
        {
          block_type_id: billingTypeId,
          name: "Manpower Billing",
          display_name: "Payment Terms",
          description: "Per head per month billing with attendance-based deductions",
          category: "commercial",
          config: { cycle: "monthly", basis: "per_head_per_month", deduction_policy: "pro_rata" },
          sequence_no: 3,
        },
        {
          block_type_id: textTypeId,
          name: "Compliance Terms",
          display_name: "Statutory Compliance",
          description: "PF, ESI, minimum wages, and Contract Labour Act compliance requirements",
          category: "content",
          config: { content_type: "compliance" },
          sequence_no: 4,
        },
        {
          block_type_id: checklistTypeId,
          name: "Monthly Compliance",
          display_name: "Monthly Compliance Checklist",
          description: "Monthly verification of statutory compliance documents",
          category: "content",
          config: { frequency: "monthly" },
          sequence_no: 5,
        }
      );
      break;

    case "sla":
      blocks.push(
        {
          block_type_id: serviceTypeId,
          name: "Primary Service",
          display_name: "Service Delivery",
          description: "Primary service with priority-based response times (P1-P4)",
          category: "core",
          config: { priority_levels: 4 },
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("fixed"),
          sequence_no: 1,
        },
        {
          block_type_id: billingTypeId,
          name: "SLA Billing",
          display_name: "Payment Terms with SLA Credits",
          description: "Fixed retainer with penalty credits for SLA breaches",
          category: "commercial",
          config: { cycle: "monthly", credit_mechanism: "penalty_deduction", max_credit_percent: 15 },
          sequence_no: 2,
        },
        {
          block_type_id: textTypeId,
          name: "SLA Definitions",
          display_name: "SLA Definitions & Targets",
          description: "Detailed SLA metrics, targets, measurement methodology, and penalties",
          category: "content",
          config: { content_type: "sla_definitions" },
          sequence_no: 3,
        }
      );
      break;

    // Default: generate minimal blocks
    default:
      blocks.push(
        {
          block_type_id: serviceTypeId,
          name: `${nomenclature.toUpperCase()} Service`,
          display_name: "Service Delivery",
          description: `Primary service block for ${nomenclature.toUpperCase()} contract`,
          category: "core",
          config: {},
          pricing_mode_id: pricingMap.get("independent"),
          price_type_id: pricingMap.get("fixed"),
          sequence_no: 1,
        },
        {
          block_type_id: billingTypeId,
          name: `${nomenclature.toUpperCase()} Billing`,
          display_name: "Payment Terms",
          description: "Billing and payment structure",
          category: "commercial",
          config: {},
          sequence_no: 2,
        },
        {
          block_type_id: textTypeId,
          name: `${nomenclature.toUpperCase()} Scope`,
          display_name: "Scope of Work",
          description: "Scope and terms",
          category: "content",
          config: { content_type: "scope" },
          sequence_no: 3,
        }
      );
      break;
  }

  return blocks;
}

interface EventTypeConfig {
  event_type: string;
  statuses: Array<{
    status_code: string;
    display_name: string;
    description: string;
    hex_color: string;
    icon_name: string;
    display_order: number;
    is_initial: boolean;
    is_terminal: boolean;
  }>;
}

function getEventTypesForNomenclatures(nomenclatures: string[]): EventTypeConfig[] {
  const events: EventTypeConfig[] = [];

  // Service visit statuses (universal for equipment/maintenance nomenclatures)
  const maintenanceNoms = ["amc", "cmc", "camc", "pmc", "bmc", "fmc", "om"];
  if (nomenclatures.some((n) => maintenanceNoms.includes(n))) {
    events.push({
      event_type: "service_visit",
      statuses: [
        { status_code: "scheduled", display_name: "Scheduled", description: "Visit scheduled", hex_color: "#3B82F6", icon_name: "Calendar", display_order: 1, is_initial: true, is_terminal: false },
        { status_code: "assigned", display_name: "Assigned", description: "Engineer assigned", hex_color: "#8B5CF6", icon_name: "UserCheck", display_order: 2, is_initial: false, is_terminal: false },
        { status_code: "en_route", display_name: "En Route", description: "Engineer on the way", hex_color: "#06B6D4", icon_name: "Navigation", display_order: 3, is_initial: false, is_terminal: false },
        { status_code: "in_progress", display_name: "In Progress", description: "Work in progress", hex_color: "#F59E0B", icon_name: "Wrench", display_order: 4, is_initial: false, is_terminal: false },
        { status_code: "pending_parts", display_name: "Pending Parts", description: "Waiting for parts", hex_color: "#F97316", icon_name: "Package", display_order: 5, is_initial: false, is_terminal: false },
        { status_code: "completed", display_name: "Completed", description: "Work completed", hex_color: "#10B981", icon_name: "CheckCircle", display_order: 6, is_initial: false, is_terminal: true },
        { status_code: "cancelled", display_name: "Cancelled", description: "Visit cancelled", hex_color: "#EF4444", icon_name: "XCircle", display_order: 7, is_initial: false, is_terminal: true },
      ],
    });
  }

  // Payment event statuses (universal)
  events.push({
    event_type: "payment",
    statuses: [
      { status_code: "pending", display_name: "Pending", description: "Payment due", hex_color: "#F59E0B", icon_name: "Clock", display_order: 1, is_initial: true, is_terminal: false },
      { status_code: "invoiced", display_name: "Invoiced", description: "Invoice sent", hex_color: "#3B82F6", icon_name: "FileText", display_order: 2, is_initial: false, is_terminal: false },
      { status_code: "partially_paid", display_name: "Partially Paid", description: "Partial payment received", hex_color: "#8B5CF6", icon_name: "CreditCard", display_order: 3, is_initial: false, is_terminal: false },
      { status_code: "paid", display_name: "Paid", description: "Full payment received", hex_color: "#10B981", icon_name: "CheckCircle", display_order: 4, is_initial: false, is_terminal: true },
      { status_code: "overdue", display_name: "Overdue", description: "Payment overdue", hex_color: "#EF4444", icon_name: "AlertTriangle", display_order: 5, is_initial: false, is_terminal: false },
    ],
  });

  // Inspection events (for FMC, O&M)
  if (nomenclatures.some((n) => ["fmc", "om"].includes(n))) {
    events.push({
      event_type: "inspection",
      statuses: [
        { status_code: "scheduled", display_name: "Scheduled", description: "Inspection scheduled", hex_color: "#3B82F6", icon_name: "Calendar", display_order: 1, is_initial: true, is_terminal: false },
        { status_code: "in_progress", display_name: "In Progress", description: "Inspection underway", hex_color: "#F59E0B", icon_name: "Search", display_order: 2, is_initial: false, is_terminal: false },
        { status_code: "observation_raised", display_name: "Observations Raised", description: "Issues found during inspection", hex_color: "#F97316", icon_name: "AlertCircle", display_order: 3, is_initial: false, is_terminal: false },
        { status_code: "completed", display_name: "Completed", description: "Inspection completed", hex_color: "#10B981", icon_name: "CheckCircle", display_order: 4, is_initial: false, is_terminal: true },
      ],
    });
  }

  return events;
}
