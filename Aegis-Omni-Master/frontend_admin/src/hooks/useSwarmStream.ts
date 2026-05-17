import { useEffect, useState } from 'react';

export interface CrisisSignal {
  crisis_id: string;
  coordinates: { latitude: number; longitude: number };
  d_score: number;
  status: 'VERIFIED' | 'CURVEBALL_EXCEPTION';
  active_agent: string;
  logs: string[];
}

export const useSwarmStream = (url: string) => {
  const [signals, setSignals] = useState<Record<string, CrisisSignal>>({});
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [isConnected, setIsConnected] = useState<boolean>(false);

  useEffect(() => {
    const ws = new WebSocket(url);
    setSocket(ws);

    ws.onopen = () => {
      setIsConnected(true);
    };

    ws.onmessage = (event) => {
      try {
        const data: CrisisSignal = JSON.parse(event.data);
        setSignals((prev) => ({
          ...prev,
          [data.crisis_id]: data,
        }));
      } catch (e) {
        console.error("Failed to parse incoming telemetry data:", e);
      }
    };

    ws.onclose = () => {
        setIsConnected(false);
        console.log("WebSocket stream closed.");
    }

    ws.onerror = (error) => {
        setIsConnected(false);
        console.error("WebSocket error:", error);
    }

    return () => {
      ws.close();
    };
  }, [url]);

  return { signals, isConnected, socket };
};
