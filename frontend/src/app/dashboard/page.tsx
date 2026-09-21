"use client";

import { useEffect, useState } from "react";
import { getDashboardStats, getEvents } from "@/lib/api";
import { DashboardStats, AppEvent } from "@/lib/types";
import { AlertTriangle, Users, FileText, Activity } from "lucide-react";

export default function DashboardOverview() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [events, setEvents] = useState<AppEvent[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;
    const load = async () => {
      try {
        const [statsData, eventsData] = await Promise.all([
          getDashboardStats(),
          getEvents()
        ]);
        if (isMounted) {
          setStats(statsData);
          setEvents(eventsData);
          setLoading(false);
        }
      } catch (e) {
        console.error(e);
        if (isMounted) setLoading(false);
      }
    };

    load();
    const interval = setInterval(load, 10000);
    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, []);

  if (loading || !stats) {
    return <div className="p-8 text-gray-400">Loading overview...</div>;
  }

  return (
    <div className="flex-1 overflow-auto p-8 bg-gray-950">
      <header className="mb-8">
        <h1 className="text-2xl font-bold text-white">System Overview</h1>
        <p className="text-gray-400 text-sm mt-1">Real-time status of border sectors</p>
      </header>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard 
          title="Current Risk" 
          value={stats.current_risk} 
          icon={<Activity className="w-6 h-6 text-blue-400" />}
          color={stats.current_risk === "HIGH" ? "text-red-400" : stats.current_risk === "MODERATE" ? "text-yellow-400" : "text-green-400"}
        />
        <StatCard 
          title="Critical Alerts" 
          value={stats.critical_alerts} 
          icon={<AlertTriangle className="w-6 h-6 text-red-400" />}
          color={stats.critical_alerts > 0 ? "text-red-400" : "text-white"}
        />
        <StatCard 
          title="Open Incidents" 
          value={stats.open_incidents} 
          icon={<FileText className="w-6 h-6 text-yellow-400" />}
          color="text-white"
        />
        <StatCard 
          title="Active Field Units" 
          value={stats.active_users} 
          icon={<Users className="w-6 h-6 text-blue-400" />}
          color="text-white"
        />
      </div>

      {/* Events Timeline */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-800 flex justify-between items-center">
          <h2 className="text-lg font-semibold text-white">Live Operations Timeline</h2>
          <div className="flex items-center text-xs text-gray-400">
            <span className="w-2 h-2 rounded-full bg-green-500 mr-2 animate-pulse"></span>
            Polling Active
          </div>
        </div>
        <div className="p-6">
          {events.length === 0 ? (
            <div className="text-center py-8 text-gray-500">No recent events</div>
          ) : (
            <div className="space-y-6">
              {events.map((event) => (
                <div key={`${event.type}-${event.id}`} className="flex items-start">
                  <div className={`mt-1 rounded-full p-1.5 ${
                    event.type === 'ALERT' && event.severity === 'CRITICAL' ? 'bg-red-500/20 text-red-400' :
                    event.type === 'ALERT' ? 'bg-yellow-500/20 text-yellow-400' :
                    'bg-blue-500/20 text-blue-400'
                  }`}>
                    {event.type === 'ALERT' ? <AlertTriangle className="w-4 h-4" /> : <FileText className="w-4 h-4" />}
                  </div>
                  <div className="ml-4 flex-1">
                    <div className="flex items-baseline justify-between">
                      <h3 className="text-sm font-medium text-gray-200">{event.title}</h3>
                      <span className="text-xs text-gray-500">
                        {new Date(event.timestamp).toLocaleTimeString()}
                      </span>
                    </div>
                    <div className="mt-1 flex items-center text-xs">
                      <span className={`font-medium ${event.severity === 'CRITICAL' ? 'text-red-400' : 'text-gray-400'}`}>
                        {event.severity}
                      </span>
                      <span className="mx-2 text-gray-700">•</span>
                      <span className="text-gray-500 uppercase tracking-wider">{event.type}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function StatCard({ title, value, icon, color }: { title: string, value: string | number, icon: React.ReactNode, color: string }) {
  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-6 flex items-center">
      <div className="p-3 rounded-lg bg-gray-800">
        {icon}
      </div>
      <div className="ml-4">
        <p className="text-sm font-medium text-gray-400">{title}</p>
        <p className={`text-2xl font-bold mt-1 ${color}`}>{value}</p>
      </div>
    </div>
  );
}
