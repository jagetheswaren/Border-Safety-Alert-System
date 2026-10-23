"use client";

import React, { useEffect, useState } from "react";
import { isReducedMotion } from "@/lib/motion";

interface DecryptedTextProps {
  text: string;
  speed?: number;
  className?: string;
}

const CHARACTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789!#$@%&*";

/**
 * React Bits inspired DecryptedText:
 * Progressive character scramble reveal for tactical BSAS operational branding.
 */
export const DecryptedText: React.FC<DecryptedTextProps> = ({
  text,
  speed = 40,
  className = "",
}) => {

  const [displayText, setDisplayText] = useState(text);

  useEffect(() => {
    if (isReducedMotion()) return;

    let iteration = 0;
    const interval = setInterval(() => {
      setDisplayText(
        text
          .split("")
          .map((char, index) => {
            if (char === " " || char === "\n") return char;
            if (index < iteration) return text[index];
            return CHARACTERS[Math.floor(Math.random() * CHARACTERS.length)];
          })
          .join("")
      );

      if (iteration >= text.length) {
        clearInterval(interval);
      }
      iteration += 1;
    }, speed);

    return () => clearInterval(interval);
  }, [text, speed]);


  return <span className={className}>{displayText}</span>;
};
