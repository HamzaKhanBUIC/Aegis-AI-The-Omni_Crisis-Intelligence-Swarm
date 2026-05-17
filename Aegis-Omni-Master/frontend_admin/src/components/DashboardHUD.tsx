import React from 'react';
import { useSwarmStream } from '../hooks/useSwarmStream';

export function DashboardHUD() {
  const { signals, isConnected } = useSwarmStream('ws://localhost:8000/stream/swarm');

  return (
    <div className="p-6 bg-slate-950 text-white min-h-screen font-mono">
      <div className="flex justify-between items-center border-b border-slate-800 pb-4 mb-6">
        <h1 className="text-2xl font-bold tracking-wider text-cyan-400">AEGIS-OMNI // COMMAND CENTER</h1>
        <div className="flex items-center gap-2">
          <span className={`w-3 h-3 rounded-full ${isConnected ? 'bg-emerald-500 animate-pulse' : 'bg-red-500'}`} />
          <span className="text-sm text-slate-400">{isConnected ? 'LIVE SWARM STREAM' : 'OFFLINE'}</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Render Map / Lists looping through Object.values(signals) */}
      </div>
    </div>
  );
}
