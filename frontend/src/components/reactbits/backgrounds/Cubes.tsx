"use client";

import React, { useEffect, useRef } from "react";
import { isReducedMotion } from "@/lib/motion";

interface CubesProps {
  className?: string;
  gridSize?: number;
  cubeSize?: number;
}

/**
 * React Bits - Cubes:
 * High-performance canvas-based isometric 3D spatial grid.
 * Perfect for Login & Startup screens without Three.js / WebGL overhead.
 */
export const Cubes: React.FC<CubesProps> = ({
  className = "",
  gridSize = 7,
  cubeSize = 36,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationFrameId: number;
    let time = 0;
    const reduced = isReducedMotion();

    const resize = () => {
      if (!canvas) return;
      canvas.width = canvas.parentElement?.clientWidth || window.innerWidth;
      canvas.height = canvas.parentElement?.clientHeight || window.innerHeight;
    };

    resize();
    window.addEventListener("resize", resize);

    const drawIsoCube = (
      isoX: number,
      isoY: number,
      size: number,
      elevation: number,
      alpha: number
    ) => {
      const topY = isoY - elevation;

      // Top face
      ctx.beginPath();
      ctx.moveTo(isoX, topY - size * 0.5);
      ctx.lineTo(isoX + size * 0.866, topY);
      ctx.lineTo(isoX, topY + size * 0.5);
      ctx.lineTo(isoX - size * 0.866, topY);
      ctx.closePath();
      ctx.fillStyle = `rgba(56, 189, 248, ${0.12 * alpha})`;
      ctx.fill();
      ctx.strokeStyle = `rgba(56, 189, 248, ${0.35 * alpha})`;
      ctx.lineWidth = 1;
      ctx.stroke();

      // Left face
      ctx.beginPath();
      ctx.moveTo(isoX - size * 0.866, topY);
      ctx.lineTo(isoX, topY + size * 0.5);
      ctx.lineTo(isoX, topY + size * 0.5 + size * 0.8);
      ctx.lineTo(isoX - size * 0.866, topY + size * 0.8);
      ctx.closePath();
      ctx.fillStyle = `rgba(2, 132, 199, ${0.08 * alpha})`;
      ctx.fill();
      ctx.strokeStyle = `rgba(56, 189, 248, ${0.2 * alpha})`;
      ctx.stroke();

      // Right face
      ctx.beginPath();
      ctx.moveTo(isoX + size * 0.866, topY);
      ctx.lineTo(isoX, topY + size * 0.5);
      ctx.lineTo(isoX, topY + size * 0.5 + size * 0.8);
      ctx.lineTo(isoX + size * 0.866, topY + size * 0.8);
      ctx.closePath();
      ctx.fillStyle = `rgba(15, 23, 42, ${0.15 * alpha})`;
      ctx.fill();
      ctx.strokeStyle = `rgba(56, 189, 248, ${0.25 * alpha})`;
      ctx.stroke();
    };

    const render = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const centerX = canvas.width * 0.5;
      const centerY = canvas.height * 0.52;

      const angleX = 0.866 * cubeSize;
      const angleY = 0.5 * cubeSize;

      for (let x = -gridSize; x <= gridSize; x++) {
        for (let y = -gridSize; y <= gridSize; y++) {
          const isoX = centerX + (x - y) * angleX;
          const isoY = centerY + (x + y) * angleY;

          const dist = Math.sqrt(x * x + y * y);
          if (dist > gridSize + 0.5) continue;
          const falloff = Math.max(0, 1 - dist / (gridSize + 0.5));

          const wave = reduced
            ? 0
            : Math.sin(time + dist * 0.6) * 12 + Math.cos(time * 0.7 + x) * 6;

          drawIsoCube(isoX, isoY, cubeSize * 0.85, wave, falloff);
        }
      }

      time += 0.02;
      animationFrameId = requestAnimationFrame(render);
    };

    render();

    return () => {
      window.removeEventListener("resize", resize);
      cancelAnimationFrame(animationFrameId);
    };
  }, [gridSize, cubeSize]);

  return (
    <canvas
      ref={canvasRef}
      className={`absolute inset-0 pointer-events-none ${className}`}
      aria-hidden="true"
    />
  );
};
