import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabaseClient';
import type { Booking } from '@/types';
import { useAuth } from '@/contexts/AuthContext';

export function useBookings(branchId: string | null = null) {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const { getCurrentUserBranch } = useAuth();
  const userBranch = getCurrentUserBranch();

  const loadBookings = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      console.log('Loading bookings, branchId:', branchId || userBranch?.id);

      let query = supabase
        .from('bookings')
        .select(`
          *,
          sender:customers!sender_id(*),
          receiver:customers!receiver_id(*),
          article:articles(*),
          from_branch_details:branches!from_branch(*),
          to_branch_details:branches!to_branch(*)
        `)
        .order('created_at', { ascending: false });

      if (branchId) {
        // If branch ID is provided, filter bookings for that branch
        query = query.or(`from_branch.eq.${branchId},to_branch.eq.${branchId}`);
      } else if (userBranch?.id) {
        // If no branch ID is provided but user has a branch, use that
        query = query.or(`from_branch.eq.${userBranch.id},to_branch.eq.${userBranch.id}`);
      }

      const { data, error: sbError } = await query;
      if (sbError) throw sbError;

      setBookings(data || []);
      console.log('Bookings loaded:', data?.length || 0);
    } catch (err) {
      console.error('Failed to load bookings:', err);
      setError(err instanceof Error ? err : new Error('Failed to load bookings'));
    } finally {
      setLoading(false);
    }
  }, [branchId, userBranch]);

  useEffect(() => {
    loadBookings();
  }, [loadBookings]);

  const createBooking = async (data: Omit<Booking, 'id' | 'created_at' | 'updated_at' | 'total_amount'>) => {
    try {
      console.log('Creating booking with data:', data);
      
      // Calculate total amount
      const totalAmount = (data.quantity * data.freight_per_qty) + 
                          (data.loading_charges || 0) + 
                          (data.unloading_charges || 0) +
                          (data.insurance_charge || 0) +
                          (data.packaging_charge || 0);
      
      // Create the booking
      const { data: newBooking, error: sbError } = await supabase
        .from('bookings')
        .insert({
          ...data,
          branch_id: data.branch_id || userBranch?.id,
          total_amount: totalAmount
        })
        .select(`
          *,
          sender:customers!sender_id(*),
          receiver:customers!receiver_id(*),
          article:articles(*),
          from_branch_details:branches!from_branch(*),
          to_branch_details:branches!to_branch(*)
        `)
        .single();

      if (sbError) throw sbError;
      
      setBookings(prev => [newBooking, ...prev]);
      console.log('Booking created successfully:', newBooking);
      return newBooking;
    } catch (err) {
      console.error('Failed to create booking:', err);
      throw err instanceof Error ? err : new Error('Failed to create booking');
    }
  };

  const updateBookingStatus = async (id: string, status: Booking['status'], additionalUpdates: Partial<Booking> = {}) => {
    try {
      console.log(`Updating booking ${id} status to ${status}`);
      
      const { data, error: sbError } = await supabase
        .from('bookings')
        .update({
          ...additionalUpdates,
          status,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select(`
          *,
          sender:customers!sender_id(*),
          receiver:customers!receiver_id(*),
          article:articles(*),
          from_branch_details:branches!from_branch(*),
          to_branch_details:branches!to_branch(*)
        `)
        .single();

      if (sbError) throw sbError;
      
      setBookings(prev => 
        prev.map(booking => booking.id === id ? data : booking)
      );
      
      console.log('Booking status updated successfully');
      return data;
    } catch (err) {
      console.error('Failed to update booking status:', err);
      throw err instanceof Error ? err : new Error('Failed to update booking status');
    }
  };

  const deleteBooking = async (id: string) => {
    try {
      console.log(`Deleting booking ${id}`);
      
      const { error: sbError } = await supabase
        .from('bookings')
        .delete()
        .eq('id', id);

      if (sbError) throw sbError;
      
      setBookings(prev => prev.filter(booking => booking.id !== id));
      console.log('Booking deleted successfully');
    } catch (err) {
      console.error('Failed to delete booking:', err);
      throw err instanceof Error ? err : new Error('Failed to delete booking');
    }
  };

  return {
    bookings,
    loading,
    error,
    createBooking,
    updateBookingStatus,
    deleteBooking,
    refresh: loadBookings
  };
}