import { useState } from 'react';
import type { Booking } from '@/types';

export function useLR(branchId: string | null = null) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  async function generateLRNumber() {
    try {
      console.log('Generating LR number, branchId:', branchId);
      
      // Generate a mock LR number with 4-digit system
      const date = new Date();
      const year = date.getFullYear().toString().slice(-2); // Last 2 digits of year
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      
      // Generate a random 4-digit sequence number
      const sequence = Math.floor(1000 + Math.random() * 9000); // Random 4-digit number between 1000-9999
      
      // Get branch code (first 2 characters)
      const branchCode = branchId ? 
        branchId.slice(0, 2).toUpperCase() : 
        'DC'; // Default code for DesiCargo
      
      const lrNumber = `${branchCode}${year}${month}-${sequence}`;
      console.log('Generated LR number:', lrNumber);
      return lrNumber;
    } catch (err) {
      console.error('Failed to generate LR number:', err);
      throw err instanceof Error ? err : new Error('Failed to generate LR number');
    }
  }

  async function createLR(data: Omit<Booking, 'id' | 'created_at' | 'updated_at' | 'total_amount'>) {
    try {
      setLoading(true);
      console.log('Creating LR with data:', data);

      // Generate LR number if not provided
      if (!data.lr_number) {
        data.lr_number = await generateLRNumber();
      }

      // Create a mock booking
      const mockBooking = {
        id: Math.random().toString(36).substring(2, 15),
        ...data,
        branch_id: branchId || 'default-branch',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        total_amount: (data.quantity * data.freight_per_qty) + (data.loading_charges || 0) + (data.unloading_charges || 0)
      };
      
      console.log('LR created successfully:', mockBooking);
      return mockBooking;
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to create LR'));
      throw err;
    } finally {
      setLoading(false);
    }
  }

  async function updateLRStatus(id: string, status: Booking['status']) {
    try {
      setLoading(true);
      console.log(`Updating LR ${id} status to ${status}`);

      // Return a mock result
      const mockResult = {
        id,
        status,
        updated_at: new Date().toISOString()
      };
      
      console.log('LR status updated successfully:', mockResult);
      return mockResult;
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to update LR status'));
      throw err;
    } finally {
      setLoading(false);
    }
  }

  async function printLR(id: string) {
    try {
      setLoading(true);
      console.log(`Printing LR ${id}`);

      // Return a mock result
      const mockLR = {
        id,
        lr_number: `DC${new Date().toISOString().slice(2, 8).replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`,
        sender: {
          name: 'John Doe',
          mobile: '9876543210'
        },
        receiver: {
          name: 'Jane Smith',
          mobile: '9876543211'
        },
        article: {
          name: 'Cloth Bundle',
          description: 'Standard cloth bundles'
        },
        from_branch: {
          name: 'Mumbai HQ',
          address: '123 Business Park, Andheri East',
          city: 'Mumbai',
          state: 'Maharashtra'
        },
        to_branch: {
          name: 'Delhi Branch',
          address: '456 Industrial Area, Okhla Phase 1',
          city: 'Delhi',
          state: 'Delhi'
        },
        quantity: 2,
        uom: 'KG',
        total_amount: 300,
        payment_type: 'Paid',
        created_at: new Date().toISOString()
      };
      
      console.log('LR data retrieved successfully for printing:', mockLR);
      return mockLR;
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to print LR'));
      throw err;
    } finally {
      setLoading(false);
    }
  }

  return {
    loading,
    error,
    createLR,
    updateLRStatus,
    printLR,
    generateLRNumber
  };
}