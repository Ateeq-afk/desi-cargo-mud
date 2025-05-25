// src/hooks/useBranches.ts
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabaseClient';
import type { Branch } from '@/types/index';

export function useBranches() {
  const [branches, setBranches] = useState<Branch[]>([]);

  useEffect(() => {
    supabase
      .from('branches')
      .select('*')
      .order('name', { ascending: true })
      .then(({ data, error }) => {
        if (error) {
          console.error('useBranches error:', error);
        } else {
          setBranches(data ?? []);
        }
      });
  }, []);

  return { branches };
}
