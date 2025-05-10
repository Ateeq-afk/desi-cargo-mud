import { useState, useEffect } from 'react';
import type { Branch } from '@/types';

export function useBranches() {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    loadBranches();
  }, []);

  async function loadBranches() {
    try {
      setLoading(true);
      console.log('Loading branches...');
      
      // Mock branch data
      const mockBranches: Branch[] = [
        {
          id: 'branch1',
          name: 'Mumbai HQ',
          code: 'MUM-HQ',
          address: '123 Business Park, Andheri East',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400069',
          phone: '022-12345678',
          email: 'mumbai@k2k.com',
          is_head_office: true,
          status: 'active',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        },
        {
          id: 'branch2',
          name: 'Delhi Branch',
          code: 'DEL-01',
          address: '456 Industrial Area, Okhla Phase 1',
          city: 'Delhi',
          state: 'Delhi',
          pincode: '110020',
          phone: '011-12345678',
          email: 'delhi@k2k.com',
          is_head_office: false,
          status: 'active',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        },
        {
          id: 'branch3',
          name: 'Bangalore Branch',
          code: 'BLR-01',
          address: '789 Tech Park, Whitefield',
          city: 'Bangalore',
          state: 'Karnataka',
          pincode: '560066',
          phone: '080-12345678',
          email: 'bangalore@k2k.com',
          is_head_office: false,
          status: 'active',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }
      ];
      
      setBranches(mockBranches);
      console.log('Branches loaded:', mockBranches.length);
    } catch (err) {
      console.error('Failed to load branches:', err);
      setError(err instanceof Error ? err : new Error('Failed to load branches'));
    } finally {
      setLoading(false);
    }
  }

  async function createBranch(branchData: Omit<Branch, 'id' | 'created_at' | 'updated_at'>) {
    try {
      console.log('Creating branch:', branchData);
      
      // Create a mock branch
      const mockBranch: Branch = {
        id: Math.random().toString(36).substring(2, 15),
        ...branchData,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      
      setBranches(prev => [...prev, mockBranch].sort((a, b) => a.name.localeCompare(b.name)));
      console.log('Branch created successfully:', mockBranch);
      return mockBranch;
    } catch (err) {
      console.error('Failed to create branch:', err);
      throw err instanceof Error ? err : new Error('Failed to create branch');
    }
  }

  async function updateBranch(id: string, updates: Partial<Branch>) {
    try {
      console.log(`Updating branch ${id}:`, updates);
      
      // Update the local state
      setBranches(prev => 
        prev.map(branch => branch.id === id ? { ...branch, ...updates, updated_at: new Date().toISOString() } : branch)
           .sort((a, b) => a.name.localeCompare(b.name))
      );
      
      const updatedBranch = branches.find(b => b.id === id);
      if (!updatedBranch) throw new Error('Branch not found');
      
      console.log('Branch updated successfully:', updatedBranch);
      return { ...updatedBranch, ...updates };
    } catch (err) {
      console.error('Failed to update branch:', err);
      throw err instanceof Error ? err : new Error('Failed to update branch');
    }
  }

  return {
    branches,
    loading,
    error,
    createBranch,
    updateBranch,
    refresh: loadBranches
  };
}