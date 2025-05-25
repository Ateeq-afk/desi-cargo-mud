import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabaseClient';

export interface Vehicle {
  id: string;
  branch_id: string;
  vehicle_number: string;
  type: 'own' | 'hired' | 'attached';
  make: string;
  model: string;
  year: number;
  status: 'active' | 'maintenance' | 'inactive';
  last_maintenance_date: string | null;
  next_maintenance_date: string | null;
  created_at: string;
  updated_at: string;
}

export function useVehicles(branchId: string | null = null) {
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const loadVehicles = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      console.log('Loading vehicles, branchId:', branchId);
      
      let query = supabase
        .from('vehicles')
        .select('*')
        .order('created_at', { ascending: false });
      
      if (branchId) {
        query = query.eq('branch_id', branchId);
      }
      
      const { data, error: sbError } = await query;

      if (sbError) throw sbError;
      setVehicles(data || []);
      console.log('Vehicles loaded:', data?.length || 0);
    } catch (err) {
      console.error('Failed to load vehicles:', err);
      setError(err instanceof Error ? err : new Error('Failed to load vehicles'));
    } finally {
      setLoading(false);
    }
  }, [branchId]);

  useEffect(() => {
    loadVehicles();
  }, [loadVehicles]);

  async function createVehicle(vehicleData: Omit<Vehicle, 'id' | 'created_at' | 'updated_at'>) {
    try {
      console.log('Creating vehicle:', vehicleData);
      
      const { data, error: sbError } = await supabase
        .from('vehicles')
        .insert(vehicleData)
        .select()
        .single();

      if (sbError) throw sbError;
      setVehicles(prev => [data, ...prev]);
      console.log('Vehicle created successfully:', data);
      return data;
    } catch (err) {
      console.error('Failed to create vehicle:', err);
      throw err instanceof Error ? err : new Error('Failed to create vehicle');
    }
  }

  async function updateVehicle(id: string, updates: Partial<Vehicle>) {
    try {
      console.log(`Updating vehicle ${id}:`, updates);
      
      const { data, error: sbError } = await supabase
        .from('vehicles')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (sbError) throw sbError;
      setVehicles(prev => prev.map(vehicle => vehicle.id === id ? data : vehicle));
      console.log('Vehicle updated successfully:', data);
      return data;
    } catch (err) {
      console.error('Failed to update vehicle:', err);
      throw err instanceof Error ? err : new Error('Failed to update vehicle');
    }
  }

  async function deleteVehicle(id: string) {
    try {
      console.log(`Deleting vehicle ${id}`);
      
      const { error: sbError } = await supabase
        .from('vehicles')
        .delete()
        .eq('id', id);

      if (sbError) throw sbError;
      setVehicles(prev => prev.filter(vehicle => vehicle.id !== id));
      console.log('Vehicle deleted successfully');
    } catch (err) {
      console.error('Failed to delete vehicle:', err);
      throw err instanceof Error ? err : new Error('Failed to delete vehicle');
    }
  }

  async function updateVehicleStatus(id: string, status: 'active' | 'maintenance' | 'inactive') {
    try {
      return await updateVehicle(id, { status });
    } catch (err) {
      console.error('Failed to update vehicle status:', err);
      throw err instanceof Error ? err : new Error('Failed to update vehicle status');
    }
  }

  return {
    vehicles,
    loading,
    error,
    createVehicle,
    updateVehicle,
    deleteVehicle,
    updateVehicleStatus,
    refresh: loadVehicles
  };
}