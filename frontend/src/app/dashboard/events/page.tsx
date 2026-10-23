"use client";

import React, { useEffect, useState } from "react";
import {
  AlertTriangle,
  FileText,
  Clock,
  RefreshCw,
  Search,
} from "lucide-react";

import { getEvents } from "@/lib/api";
import { AppEvent } from "@/lib/types";
import { PillNav } from "@/components/reactbits/PillNav";
import { LoadingState } from "@/components/ui/LoadingState";
import { EmptyState } from "@/components/ui/EmptyState";
import { SpotlightCard } from "@/components/reactbits/SpotlightCard";

export default function ActivityEventsPage() {
  const [events, setEvents] = useState<AppEvent[]>([]);
  const [filter, setFilter] = useState<string>("ALL");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchEvents = async (isSilent = false) => {
    await Promise.resolve();
    if (!isSilent) setLoading(true);
    else setRefreshing(true);

    try {
      const data = await getEvents();
      setEvents(data || []);
      setLoading(false);
      setRefreshing(false);
    } catch (err) {
      console.error("Failed to load activity events:", err);
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    let active = true;
    (async () => {
      await Promise.resolve();
      if (!active) return;
      try {
        const data = await getEvents();
        if (active) {
          setEvents(data || []);
          setLoading(false);
        }
      } catch (err) {
        console.error("Failed to load activity events:", err);
        if (active) setLoading(false);
      }
    })();
    const interval = setInterval(() => fetchEvents(true), 15000);
    return () => {
      active = false;
      clearInterval(interval);
    };
  }, []);


  const filtered = events.filter((e) => {
    const matchesFilter =
      filter === "ALL" ||
      (filter === "ALERTS" && e.type === "ALERT") ||
      (filter === "INCIDENTS" && e.type === "INCIDENT");

    const matchesSearch =
      e.title.toLowerCase().includes(search.toLowerCase()) ||
      (e.data && e.data.toLowerCase().includes(search.toLowerCase()));

    return matchesFilter && matchesSearch;
  });


  return (
    <div className="flex-1 p-4 sm:p-6 lg:p-8 space-y-6 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-800/80">
        <div>
          <div className="inline-flex items-center gap-2 text-xs font-semibold text-sky-400 uppercase tracking-wider mb-1">
            <span className="w-1.5 h-1.5 rounded-full bg-sky-400" />
            Audit Trail & Event Log
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">
            Operational Activity Logs
          </h1>
          <p className="text-xs text-slate-400 mt-0.5">
            Chronological audit of perimeter sensor triggers, mobile syncs, and telemetry events
          </p>
        </div>

        <div className="flex items-center gap-3">
          <PillNav
            value={filter}
            onChange={(val) => setFilter(val)}
            options={[
              { id: "ALL", label: "All Events" },
              { id: "ALERTS", label: "Alerts" },
              { id: "INCIDENTS", label: "Incidents" },
            ]}
          />

          <button
            type="button"
            onClick={() => fetchEvents(true)}
            disabled={refreshing}
            className="p-2 rounded-xl bg-slate-900 border border-slate-800 text-slate-300 hover:text-white transition-colors"
            title="Refresh logs"
          >
            <RefreshCw
              className={`w-4 h-4 ${refreshing ? "animate-spin text-sky-400" : ""}`}
            />
          </button>
        </div>
      </div>

      {/* Filter toolbar */}
      <div className="p-3.5 rounded-2xl bg-slate-900 border border-slate-800 flex items-center gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search activity events..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-slate-800 border border-slate-700/80 text-white text-xs rounded-xl pl-9 pr-3 py-2 focus:outline-none focus:border-sky-400"
          />
        </div>
      </div>

      {/* Timeline Stream */}
      <SpotlightCard className="p-6">
        {loading ? (
          <LoadingState label="Retrieving system activity stream..." />
        ) : filtered.length === 0 ? (
          <EmptyState
            title="No Activity Events"
            description="No recent operational logs match your filter criteria."
          />
        ) : (
          <div className="relative pl-6 space-y-6 before:absolute before:left-2.5 before:top-2 before:bottom-2 before:w-0.5 before:bg-slate-800">
            {filtered.map((item) => (
              <div key={`${item.type}-${item.id}`} className="relative flex items-start gap-4">
                <div
                  className={`absolute -left-[27px] mt-0.5 p-1.5 rounded-full border ${
                    item.type === "ALERT" && item.severity === "CRITICAL"
                      ? "bg-rose-950 border-rose-800 text-rose-400"
                      : item.type === "ALERT"
                      ? "bg-amber-950 border-amber-800 text-amber-400"
                      : "bg-sky-950 border-sky-800 text-sky-400"
                  }`}
                >
                  {item.type === "ALERT" ? (
                    <AlertTriangle className="w-3 h-3" />
                  ) : (
                    <FileText className="w-3 h-3" />
                  )}
                </div>

                <div className="flex-1 p-3.5 rounded-xl bg-slate-950/60 border border-slate-800 hover:border-slate-700 transition-colors">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-xs font-semibold text-white">{item.title}</p>
                    <span className="text-[10px] text-slate-400 font-mono flex items-center gap-1 shrink-0">
                      <Clock className="w-3 h-3" />
                      {new Date(item.timestamp).toLocaleString()}
                    </span>
                  </div>
                  <p className="text-xs text-slate-300 mt-1 leading-relaxed">
                    {item.data || "Operational event recorded"}
                  </p>
                </div>
              </div>
            ))}

          </div>
        )}
      </SpotlightCard>
    </div>
  );
}
