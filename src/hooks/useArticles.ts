import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import type { Article, CustomerArticleRate } from '@/types';

export function useArticles(branchId: string | null = null) {
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    loadArticles();
  }, [branchId]);

  async function loadArticles() {
    try {
      setLoading(true);
      console.log('Loading articles, branchId:', branchId);
      
      // Mock article data
      const mockArticles: Article[] = [
        {
          id: 'article1',
          branch_id: 'branch1',
          name: 'Cloth Bundle',
          description: 'Standard cloth bundles',
          base_rate: 100,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          branch_name: 'Mumbai HQ',
          hsn_code: '6302',
          tax_rate: 18,
          unit_of_measure: 'bundle',
          min_quantity: 1,
          is_fragile: false,
          requires_special_handling: false
        },
        {
          id: 'article2',
          branch_id: 'branch1',
          name: 'Cloth Box',
          description: 'Boxed cloth materials',
          base_rate: 150,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          branch_name: 'Mumbai HQ',
          hsn_code: '6305',
          tax_rate: 18,
          unit_of_measure: 'box',
          min_quantity: 1,
          is_fragile: false,
          requires_special_handling: false
        },
        {
          id: 'article3',
          branch_id: 'branch2',
          name: 'Garments',
          description: 'Ready-made garments',
          base_rate: 200,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          branch_name: 'Delhi Branch',
          hsn_code: '6309',
          tax_rate: 12,
          unit_of_measure: 'pcs',
          min_quantity: 1,
          is_fragile: true,
          requires_special_handling: true,
          notes: 'Handle with care. Fragile items.'
        },
        {
          id: 'article4',
          branch_id: 'branch2',
          name: 'Fabric Rolls',
          description: 'Rolled fabric materials',
          base_rate: 180,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          branch_name: 'Delhi Branch',
          hsn_code: '6307',
          tax_rate: 18,
          unit_of_measure: 'roll',
          min_quantity: 1,
          is_fragile: false,
          requires_special_handling: true
        },
        {
          id: 'article5',
          branch_id: 'branch3',
          name: 'Textile Machinery',
          description: 'Textile manufacturing equipment',
          base_rate: 500,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          branch_name: 'Bangalore Branch',
          hsn_code: '8445',
          tax_rate: 28,
          unit_of_measure: 'pcs',
          min_quantity: 1,
          is_fragile: true,
          requires_special_handling: true,
          notes: 'Heavy machinery. Requires special handling equipment.'
        },
        {
          id: 'article6',
          branch_id: 'branch1',
          name: 'Raw Materials',
          description: 'Raw textile materials',
          base_rate: 120,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          branch_name: 'Mumbai HQ',
          hsn_code: '5201',
          tax_rate: 5,
          unit_of_measure: 'kg',
          min_quantity: 5,
          is_fragile: false,
          requires_special_handling: false
        },
        {
          id: 'article7',
          branch_id: 'branch3',
          name: 'Yarn Boxes',
          description: 'Boxes of yarn',
          base_rate: 90,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          branch_name: 'Bangalore Branch',
          hsn_code: '5207',
          tax_rate: 12,
          unit_of_measure: 'box',
          min_quantity: 1,
          is_fragile: false,
          requires_special_handling: false
        },
        {
          id: 'article8',
          branch_id: 'branch2',
          name: 'Accessories',
          description: 'Textile accessories and supplies',
          base_rate: 80,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          branch_name: 'Delhi Branch',
          hsn_code: '6217',
          tax_rate: 18,
          unit_of_measure: 'pcs',
          min_quantity: 10,
          is_fragile: false,
          requires_special_handling: false
        }
      ];
      
      // Filter by branch if specified
      const filteredArticles = branchId 
        ? mockArticles.filter(a => a.branch_id === branchId)
        : mockArticles;
      
      setArticles(filteredArticles);
      console.log('Articles loaded:', filteredArticles.length);
    } catch (err) {
      console.error('Failed to load articles:', err);
      setError(err instanceof Error ? err : new Error('Failed to load articles'));
    } finally {
      setLoading(false);
    }
  }

  async function createArticle(articleData: Omit<Article, 'id' | 'created_at' | 'updated_at'>) {
    try {
      console.log('Creating article:', articleData);
      
      // Create a mock article
      const mockArticle: Article = {
        id: Math.random().toString(36).substring(2, 15),
        ...articleData,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        branch_name: articleData.branch_id === 'branch1' ? 'Mumbai HQ' : 
                     articleData.branch_id === 'branch2' ? 'Delhi Branch' : 
                     articleData.branch_id === 'branch3' ? 'Bangalore Branch' : 'Unknown Branch'
      };
      
      setArticles(prev => [...prev, mockArticle].sort((a, b) => a.name.localeCompare(b.name)));
      console.log('Article created successfully:', mockArticle);
      return mockArticle;
    } catch (err) {
      console.error('Failed to create article:', err);
      throw err instanceof Error ? err : new Error('Failed to create article');
    }
  }

  async function updateArticle(id: string, updates: Partial<Article>) {
    try {
      console.log(`Updating article ${id}:`, updates);
      
      // Update the local state
      setArticles(prev => 
        prev.map(article => article.id === id 
          ? { ...article, ...updates, updated_at: new Date().toISOString() } 
          : article
        ).sort((a, b) => a.name.localeCompare(b.name))
      );
      
      const updatedArticle = articles.find(a => a.id === id);
      if (!updatedArticle) throw new Error('Article not found');
      
      console.log('Article updated successfully:', { ...updatedArticle, ...updates });
      return { ...updatedArticle, ...updates };
    } catch (err) {
      console.error('Failed to update article:', err);
      throw err instanceof Error ? err : new Error('Failed to update article');
    }
  }

  async function deleteArticle(id: string) {
    try {
      console.log(`Deleting article ${id}`);
      
      // Update the local state
      setArticles(prev => prev.filter(article => article.id !== id));
      console.log('Article deleted successfully');
    } catch (err) {
      console.error('Failed to delete article:', err);
      throw err instanceof Error ? err : new Error('Failed to delete article');
    }
  }

  async function getCustomerRates(customerId: string) {
    try {
      console.log(`Getting rates for customer ${customerId}`);
      
      // Mock customer article rates
      const mockRates: CustomerArticleRate[] = [
        {
          id: 'rate1',
          customer_id: customerId,
          article_id: 'article1',
          rate: 90, // Discounted rate
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        },
        {
          id: 'rate2',
          customer_id: customerId,
          article_id: 'article2',
          rate: 140, // Discounted rate
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }
      ];
      
      console.log('Customer rates loaded:', mockRates.length);
      return mockRates;
    } catch (err) {
      console.error('Failed to load customer rates:', err);
      throw err instanceof Error ? err : new Error('Failed to load customer rates');
    }
  }

  async function updateCustomerRate(customerId: string, articleId: string, rate: number) {
    try {
      console.log(`Updating rate for customer ${customerId}, article ${articleId} to ${rate}`);
      
      // Create a mock rate
      const mockRate: CustomerArticleRate = {
        id: Math.random().toString(36).substring(2, 15),
        customer_id: customerId,
        article_id: articleId,
        rate,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      
      console.log('Customer rate updated successfully:', mockRate);
      return mockRate;
    } catch (err) {
      console.error('Failed to update customer rate:', err);
      throw err instanceof Error ? err : new Error('Failed to update customer rate');
    }
  }

  return {
    articles,
    loading,
    error,
    createArticle,
    updateArticle,
    deleteArticle,
    getCustomerRates,
    updateCustomerRate,
    refresh: loadArticles
  };
}