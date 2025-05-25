import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabaseClient';
import type { Customer } from '@/types';

export function useCustomers(branchId: string | null = null) {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const loadCustomers = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      console.log('Loading customers, branchId:', branchId);

      let query = supabase
        .from('customers')
        .select(`
          *,
          branch:branches(name, code)
        `)
        .order('name', { ascending: true });

      if (branchId) {
        query = query.eq('branch_id', branchId);
      }

      const { data, error: sbError } = await query;
      if (sbError) throw sbError;

      // Transform the data to match our Customer type
      const transformedData = data?.map(customer => ({
        ...customer,
        branch_name: customer.branch?.name,
        branch_code: customer.branch?.code
      })) || [];

      setCustomers(transformedData);
      console.log('Customers loaded:', transformedData.length);
    } catch (err) {
      console.error('Failed to load customers:', err);
      setError(err instanceof Error ? err : new Error('Failed to load customers'));
    } finally {
      setLoading(false);
    }
  }, [branchId]);

  useEffect(() => {
    loadCustomers();
  }, [loadCustomers]);

  const createCustomer = async (customerData: Omit<Customer, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      console.log('Creating customer:', customerData);
      
      const { data, error: sbError } = await supabase
        .from('customers')
        .insert(customerData)
        .select(`
          *,
          branch:branches(name, code)
        `)
        .single();

      if (sbError) throw sbError;
      
      // Transform the data to match our Customer type
      const transformedData = {
        ...data,
        branch_name: data.branch?.name,
        branch_code: data.branch?.code
      };
      
      setCustomers(prev => [transformedData, ...prev]);
      console.log('Customer created successfully:', transformedData);
      return transformedData;
    } catch (err) {
      console.error('Failed to create customer:', err);
      throw err instanceof Error ? err : new Error('Failed to create customer');
    }
  };

  const updateCustomer = async (id: string, updates: Partial<Customer>) => {
    try {
      console.log(`Updating customer ${id}:`, updates);
      
      const { data, error: sbError } = await supabase
        .from('customers')
        .update(updates)
        .eq('id', id)
        .select(`
          *,
          branch:branches(name, code)
        `)
        .single();

      if (sbError) throw sbError;
      
      // Transform the data to match our Customer type
      const transformedData = {
        ...data,
        branch_name: data.branch?.name,
        branch_code: data.branch?.code
      };
      
      setCustomers(prev => prev.map(customer => 
        customer.id === id ? transformedData : customer
      ));
      
      console.log('Customer updated successfully:', transformedData);
      return transformedData;
    } catch (err) {
      console.error('Failed to update customer:', err);
      throw err instanceof Error ? err : new Error('Failed to update customer');
    }
  };

  const deleteCustomer = async (id: string) => {
    try {
      console.log(`Deleting customer ${id}`);
      
      // First check if customer has bookings
      const { count, error: countError } = await supabase
        .from('bookings')
        .select('*', { count: 'exact', head: true })
        .or(`sender_id.eq.${id},receiver_id.eq.${id}`);
      
      if (countError) throw countError;
      
      if (count && count > 0) {
        throw new Error('Cannot delete customer with existing bookings');
      }
      
      // If no bookings, proceed with deletion
      const { error: deleteError } = await supabase
        .from('customers')
        .delete()
        .eq('id', id);
      
      if (deleteError) throw deleteError;
      
      // Update local state
      setCustomers(prev => prev.filter(customer => customer.id !== id));
      console.log('Customer deleted successfully');
    } catch (err) {
      console.error('Failed to delete customer:', err);
      throw err instanceof Error ? err : new Error(
        err.message === 'Cannot delete customer with existing bookings'
          ? err.message
          : 'Failed to delete customer'
      );
    }
  };

  return {
    customers,
    loading,
    error,
    createCustomer,
    updateCustomer,
    deleteCustomer,
    refresh: loadCustomers
  };
}