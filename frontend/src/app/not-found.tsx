"use client";

import React from "react";
import Link from "next/link";
import { Compass, ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/Button";

export default function NotFoundPage() {
  return (
    <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-6 text-center text-white relative overflow-hidden bg-tactical-grid">
      <div className="relative z-10 max-w-md space-y-4">
        <div className="inline-flex p-3 rounded-2xl bg-sky-950/80 border border-sky-800/60 text-sky-400 mb-2">
          <Compass className="w-10 h-10 animate-spin" style={{ animationDuration: "12s" }} />
        </div>

        <div className="font-mono text-xs font-bold text-sky-400 uppercase tracking-widest">
          ERROR 404 · OUT OF BOUNDS
        </div>

        <h1 className="text-3xl font-extrabold tracking-tight text-white">
          Location Not Found
        </h1>

        <p className="text-xs text-slate-400 leading-relaxed">
          The requested coordinate or navigational route does not exist within the BSAS monitored registry.
        </p>

        <div className="pt-4">
          <Link href="/dashboard">
            <Button variant="primary" icon={<ArrowRight className="w-4 h-4" />}>
              Return to Operations Dashboard
            </Button>
          </Link>
        </div>
      </div>
    </div>
  );
}
