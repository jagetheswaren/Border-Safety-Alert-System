"use client";

import { useCallback, useEffect, useState } from 'react';

/** Keeps failures distinct from empty results and suppresses outdated requests. */
export function useResource<T>(loader: () => Promise<T>, intervalMs?: number) {
  const [revision, setRevision] = useState(0);
  const [result, setResult] = useState<{ loader: typeof loader; data?: T; error?: Error; checkedAt?: Date }>();
  const [refreshing, setRefreshing] = useState(false);
  const refresh = useCallback(() => { setRefreshing(true); setRevision(value => value + 1); }, []);
  useEffect(() => {
    let active = true;
    const load = async () => {
      try {
        const data = await loader();
        if (active) setResult({ loader, data, checkedAt: new Date() });
      } catch (error) {
        if (active) setResult({ loader, error: error instanceof Error ? error : new Error('Unable to load data.') });
      } finally {
        if (active) setRefreshing(false);
      }
    };
    void load();
    const timer = intervalMs ? setInterval(load, intervalMs) : undefined;
    return () => { active = false; if (timer) clearInterval(timer); };
  }, [loader, revision, intervalMs]);
  const current = result?.loader === loader ? result : undefined;
  return { data: current?.data, error: current?.error, checkedAt: current?.checkedAt, loading: !current, refreshing, refresh };
}

