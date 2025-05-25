// src/hooks/useArticles.ts
import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabaseClient';
import type { Article, CustomerArticleRate } from '@/types';

export function useArticles(branchId?: string) {
  const [articles, setArticles]   = useState<Article[]>([]);
  const [loading, setLoading]     = useState<boolean>(false);
  const [error, setError]         = useState<Error | null>(null);

  // 1) Fetch the list of articles (filtered by branchId if provided)
  const loadArticles = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      let query = supabase
        .from<Article>('articles')
        .select('*')
        .order('name', { ascending: true });

      if (branchId) {
        query = query.eq('branch_id', branchId);
      }

      const { data, error: sbError } = await query;
      if (sbError) throw sbError;

      setArticles(data ?? []);
    } catch (err) {
      console.error('useArticles.loadArticles error:', err);
      setError(err instanceof Error ? err : new Error('Failed to load articles'));
    } finally {
      setLoading(false);
    }
  }, [branchId]);

  // reload whenever branchId changes
  useEffect(() => {
    loadArticles();
  }, [loadArticles]);


  // 2) Create a new article
  async function createArticle(input: Omit<Article, 'id'|'created_at'|'updated_at'>) {
    try {
      setLoading(true);
      const { data, error: sbError } = await supabase
        .from<Article>('articles')
        .insert(input)
        .select()
        .single();

      if (sbError) throw sbError;
      setArticles(prev => [...prev, data]);
      return data;
    } finally {
      setLoading(false);
    }
  }

  // 3) Update an existing article
  async function updateArticle(id: string, updates: Partial<Article>) {
    try {
      setLoading(true);
      const { data, error: sbError } = await supabase
        .from<Article>('articles')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (sbError) throw sbError;
      setArticles(prev => prev.map(a => (a.id === id ? data : a)));
      return data;
    } finally {
      setLoading(false);
    }
  }

  // 4) Delete an article
  async function deleteArticle(id: string) {
    try {
      setLoading(true);
      const { error: sbError } = await supabase
        .from<Article>('articles')
        .delete()
        .eq('id', id);

      if (sbError) throw sbError;
      setArticles(prev => prev.filter(a => a.id !== id));
    } finally {
      setLoading(false);
    }
  }

  // 5) Fetch all customer-specific rates for a given customer
  async function getCustomerRates(customerId: string) {
    try {
      setLoading(true);
      const { data, error: sbError } = await supabase
        .from<CustomerArticleRate>('customer_article_rates')
        .select('*')
        .eq('customer_id', customerId);

      if (sbError) throw sbError;
      return data ?? [];
    } finally {
      setLoading(false);
    }
  }

  // 6) Upsert (insert or update) a specific customer-article rate
  async function updateCustomerRate(
    customerId: string,
    articleId: string,
    rate: number
  ) {
    try {
      setLoading(true);
      const payload = { customer_id: customerId, article_id: articleId, rate };
      const { data, error: sbError } = await supabase
        .from<CustomerArticleRate>('customer_article_rates')
        .upsert(payload, { onConflict: ['customer_id', 'article_id'] })
        .select()
        .single();

      if (sbError) throw sbError;
      return data;
    } finally {
      setLoading(false);
    }
  }

  return {
    articles,
    loading,
    error,
    refresh: loadArticles,
    createArticle,
    updateArticle,
    deleteArticle,
    getCustomerRates,
    updateCustomerRate,
  };
}
