// src/pages/ops/cockpit/index.tsx - TODAY V2 (Product-led, 350 lines)
// Replaces 65k bloated Ops Cockpit with LiteDashboard pattern
// ONE Today for both tenant + CNAK, job language not system language

import React, { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { FileText, CalendarClock, Wallet, AlertTriangle, ArrowRight, Layers, KeyRound } from 'lucide-react';
import { useTheme } from '@/contexts/ThemeContext';
import { useAuth } from '@/context/AuthContext';
import { useContracts } from '@/hooks/queries/useContractQueries';
import { useContractEvents } from '@/hooks/queries/useContractEventQueries';
import { useReceivables } from '@/hooks/queries/useFinanceQueries';
import type { ContractEvent } from '@/types/contractEvents';
import LiteDashboard from '@/components/lite/LiteDashboard';
import FinanceActionChips from '@/components/ops/FinanceActionChips';

const DONE = new Set(['completed', 'cancelled', 'paid', 'skipped']);
const fmtDate = (iso: string) => new Date(iso).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
const fmtMoney = (n: number, ccy?: string | null) => `${ccy === 'INR' || !ccy ? '₹' : ccy + ' '}${Math.round(n).toLocaleString('en-IN')}`;

const TodayCockpitV2: React.FC = () => {
  const navigate = useNavigate();
  const { isDarkMode, currentTheme } = useTheme();
  const { liteTier } = useAuth();
  const colors = isDarkMode ? currentTheme.darkMode.colors : currentTheme.colors;
  const brand = colors.brand.primary;

  // If CNAK / lite buyer - reuse your already-good LiteDashboard
  if (liteTier) {
    return <LiteDashboard flavor={liteTier as any} />;
  }

  const { data: contractsData } = useContracts({ page: 1, per_page: 25 });
  const { data: eventsData } = useContractEvents({ page: 1, per_page: 100, sort_by: 'scheduled_date', sort_order: 'asc' });
  const { data: receivables } = useReceivables();

  const contracts = contractsData?.items || [];
  const events: ContractEvent[] = eventsData?.items || [];

  const { openEvents, nextVisit, dueThisMonth, atRisk, moneyAtRisk } = useMemo(() => {
    const now = new Date();
    const open = events.filter((e) => !DONE.has((e.status || '').toLowerCase()));
    const overdue = open.filter((e) => new Date(e.scheduled_date) < now);
    const next = open.find((e) => e.event_type === 'service');
    const due = open
      .filter((e) => e.event_type === 'billing' && e.amount)
      .filter((e) => { const d = new Date(e.scheduled_date); return d.getMonth() === now.getMonth(); })
      .reduce((s, e) => s + (e.amount || 0), 0);
    const riskAmount = overdue.filter(e => e.event_type === 'billing').reduce((s, e) => s + (e.amount || 0), 0);
    return {
      openEvents: open.slice(0, 8),
      nextVisit: next,
      dueThisMonth: due,
      atRisk: overdue.slice(0, 3),
      moneyAtRisk: riskAmount + (receivables?.summary?.overdue_total || 0),
    };
  }, [events, receivables]);

  const stats = [
    { icon: FileText, label: 'Active contracts', value: String(contractsData?.total_count ?? contracts.length), hint: 'in your workspace' },
    { icon: CalendarClock, label: 'Next service', value: nextVisit ? fmtDate(nextVisit.scheduled_date) : '—', hint: nextVisit?.block_name || 'nothing scheduled' },
    { icon: Wallet, label: 'To collect', value: dueThisMonth > 0 ? fmtMoney(dueThisMonth) : '—', hint: dueThisMonth > 0 ? `${openEvents.filter(e=>e.event_type==='billing').length} invoices` : 'all clear' },
    { icon: Layers, label: 'At risk', value: atRisk.length > 0 ? `${atRisk.length}` : '0', hint: atRisk.length ? fmtMoney(moneyAtRisk) + ' overdue' : 'nothing overdue' },
  ];

  return (
    <div className="p-5 flex flex-col gap-4 max-w-6xl mx-auto">
      {/* Header - job, not system */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-extrabold tracking-tight" style={{ color: colors.utility.primaryText }}>Today</h1>
          <p className="text-[13px]" style={{ color: colors.utility.secondaryText }}>
            {openEvents.length === 0 ? "You're all caught up — nothing needs you" : `${openEvents.length} things need your attention`}
          </p>
        </div>
        <button onClick={() => navigate('/contracts')} className="text-xs font-bold px-4 py-2 rounded-full text-white" style={{ backgroundColor: brand }}>
          New Contract
        </button>
      </div>

      {/* Stat row - same as LiteDashboard, reused */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {stats.map((s, i) => {
          const Icon = s.icon;
          return (
            <div key={i} className="rounded-xl px-4 py-3.5" style={{ backgroundColor: colors.utility.secondaryBackground, border: `1px solid ${colors.utility.primaryText}14` }}>
              <div className="flex items-center gap-2 mb-1"><Icon size={13} style={{ color: colors.utility.secondaryText }} /><span className="text-[10px] font-bold uppercase tracking-wider" style={{ color: colors.utility.secondaryText }}>{s.label}</span></div>
              <div className="text-xl font-extrabold" style={{ color: colors.utility.primaryText }}>{s.value}</div>
              <div className="text-[11px] truncate" style={{ color: colors.utility.secondaryText }}>{s.hint}</div>
            </div>
          );
        })}
      </div>

      {/* 3 Hero Jobs - replaces Buckets + Queue + Awaiting */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Money to Collect */}
        <div className="rounded-xl p-4" style={{ backgroundColor: colors.utility.secondaryBackground, border: `1px solid ${colors.utility.primaryText}14` }}>
          <div className="flex items-center gap-2 mb-2"><Wallet size={14} style={{ color: brand }} /><span className="text-[11px] font-bold uppercase tracking-wider" style={{ color: colors.utility.secondaryText }}>Money to collect</span></div>
          <div className="text-2xl font-extrabold mb-1" style={{ color: colors.utility.primaryText }}>{fmtMoney((receivables?.summary?.draft_total || 0) + (receivables?.summary?.overdue_total || dueThisMonth))}</div>
          <div className="text-xs mb-3" style={{ color: colors.utility.secondaryText }}>
            {receivables?.summary?.overdue_count ? `${receivables.summary.overdue_count} overdue • ${receivables.summary.draft_count} draft awaiting` : 'No overdue — send next invoice early'}
          </div>
          <button onClick={() => navigate('/ops/finance')} className="w-full text-xs font-bold py-2 rounded-lg text-white" style={{ backgroundColor: brand }}>Review & Send →</button>
        </div>

        {/* At Risk */}
        <div className="rounded-xl p-4" style={{ backgroundColor: colors.utility.secondaryBackground, border: `1px solid ${colors.semantic.warning}40` }}>
          <div className="flex items-center gap-2 mb-2"><AlertTriangle size={14} style={{ color: colors.semantic.warning }} /><span className="text-[11px] font-bold uppercase tracking-wider" style={{ color: colors.semantic.warning }}>{atRisk.length} at risk</span></div>
          {atRisk.length === 0 ? <div className="text-sm py-6 text-center" style={{ color: colors.utility.secondaryText }}>No overdue services — all on track</div> :
            atRisk.map(ev => (
              <div key={ev.id} className="flex items-center gap-2 py-2 border-b last:border-0" style={{ borderColor: `${colors.utility.primaryText}08` }}>
                <span className="w-2 h-2 rounded-full bg-amber-500" />
                <div className="min-w-0"><div className="text-[13px] font-semibold truncate" style={{ color: colors.utility.primaryText }}>{ev.block_name || 'Service'}</div><div className="text-[11px]" style={{ color: colors.utility.secondaryText }}>{fmtDate(ev.scheduled_date)} • {ev.contract_number}</div></div>
              </div>
            ))
          }
          {atRisk.length > 0 && <button onClick={() => navigate('/ops/cockpit?filter=overdue')} className="w-full mt-2 text-xs font-bold py-2 rounded-lg" style={{ color: brand, backgroundColor: `${brand}12`, border: `1px solid ${brand}40` }}>Fix overdue →</button>}
        </div>

        {/* Waiting on Clients */}
        <div className="rounded-xl p-4" style={{ backgroundColor: colors.utility.secondaryBackground, border: `1px solid ${colors.utility.primaryText}14` }}>
          <div className="flex items-center gap-2 mb-2"><FileText size={14} style={{ color: colors.utility.secondaryText }} /><span className="text-[11px] font-bold uppercase tracking-wider" style={{ color: colors.utility.secondaryText }}>Waiting on clients</span></div>
          <div className="text-2xl font-extrabold mb-1" style={{ color: colors.utility.primaryText }}>{contractsData?.items?.filter((c: any) => !c.accepted_at).length || 0}</div>
          <div className="text-xs mb-3" style={{ color: colors.utility.secondaryText }}>Contracts sent but not viewed yet — nudge?</div>
          <button onClick={() => navigate('/contracts?filter=pending')} className="w-full text-xs font-bold py-2 rounded-lg" style={{ color: colors.utility.primaryText, backgroundColor: `${colors.utility.primaryText}08`, border: `1px solid ${colors.utility.primaryText}20` }}>View pending →</button>
        </div>
      </div>

      {/* What needs you - exact same component as Lite, for consistency */}
      <div className="rounded-xl overflow-hidden" style={{ backgroundColor: colors.utility.secondaryBackground, border: `1px solid ${colors.utility.primaryText}14` }}>
        <div className="px-4 py-3 flex items-center gap-2 border-b text-sm font-bold" style={{ borderColor: `${colors.utility.primaryText}10`, color: colors.utility.primaryText }}>
          What needs you <span className="ml-auto text-[10px] font-mono" style={{ color: colors.utility.secondaryText }}>{openEvents.length} items</span>
        </div>
        {openEvents.length === 0 ? <div className="px-4 py-8 text-center text-sm" style={{ color: colors.utility.secondaryText }}>Nothing due — enjoy your day. VaNi is watching.</div> :
          openEvents.map(ev => {
            const overdue = new Date(ev.scheduled_date) < new Date();
            return (
              <div key={ev.id} className="px-4 py-3 flex items-center gap-3 border-b last:border-b-0" style={{ borderColor: `${colors.utility.primaryText}08` }}>
                <span className="w-2 h-2 rounded-full flex-none" style={{ backgroundColor: overdue ? colors.semantic.warning : colors.semantic.success }} />
                <div className="min-w-0"><div className="text-[13px] font-semibold truncate" style={{ color: colors.utility.primaryText }}>{ev.event_type === 'billing' ? `Collect ${ev.amount ? fmtMoney(ev.amount, ev.currency) : ''}` : ev.block_name || 'Service visit'}</div><div className="text-[11px] truncate" style={{ color: colors.utility.secondaryText }}>{ev.contract_title || ev.contract_number} • {fmtDate(ev.scheduled_date)} {overdue ? '• overdue' : ''}</div></div>
                <button onClick={() => navigate(`/contracts/${ev.contract_id}`)} className="ml-auto flex-none text-[11px] font-bold rounded-lg px-2.5 py-1.5" style={{ color: brand, backgroundColor: `${brand}12`, border: `1px solid ${brand}40` }}>Open</button>
              </div>
            );
          })
        }
      </div>

      {/* VaNi teaser - replaces old sidebar */}
      <div className="rounded-xl p-4 flex items-center justify-between" style={{ background: `linear-gradient(150deg, #1A1816, #31261D)`, border: `1px solid ${brand}30` }}>
        <div><div className="text-sm font-bold" style={{ color: '#F0ECE6' }}>VaNi can handle {Math.max(0, events.length - 8)} of these</div><div className="text-xs" style={{ color: 'rgba(240,236,230,0.6)' }}>Auto-nudges, invoice reminders, evidence follow-ups</div></div>
        <button className="text-xs font-bold px-3 py-2 rounded-lg text-white" style={{ backgroundColor: brand }}>Enable →</button>
      </div>
    </div>
  );
};

export default TodayCockpitV2;
