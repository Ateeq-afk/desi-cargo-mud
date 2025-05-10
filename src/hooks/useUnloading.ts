import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import type { OGPL } from '@/types';
import { useNotificationSystem } from '@/hooks/useNotificationSystem';

export function useUnloading(organizationId: string | null) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const { showSuccess, showError } = useNotificationSystem();

  const getIncomingOGPLs = async () => {
    try {
      setLoading(true);
      setError(null);

      // In a real implementation, this would fetch from Supabase
      // For demo purposes, we'll create mock data
      const mockOGPLs = [
        {
          id: 'ogpl1',
          organization_id: organizationId,
          ogpl_number: 'OGPL-20250101-0001',
          name: 'Mumbai to Delhi Transit',
          transit_mode: 'direct',
          transit_date: '2025-01-01',
          from_station: 'branch1',
          to_station: 'branch2',
          departure_time: '08:00',
          arrival_time: '18:00',
          supervisor_name: 'Rajesh Kumar',
          supervisor_mobile: '9876543210',
          primary_driver_name: 'Sunil Sharma',
          primary_driver_mobile: '9876543211',
          status: 'in_transit',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          vehicle: {
            id: 'vehicle1',
            vehicle_number: 'MH01AB1234',
            type: 'own'
          },
          from_station_details: {
            id: 'branch1',
            name: 'Mumbai HQ',
            code: 'MUM-HQ'
          },
          to_station_details: {
            id: 'branch2',
            name: 'Delhi Branch',
            code: 'DEL-01'
          },
          loading_records: [
            {
              id: 'lr1',
              ogpl_id: 'ogpl1',
              booking_id: 'booking1',
              booking: {
                id: 'booking1',
                lr_number: 'LR-20250101-0001',
                quantity: 2,
                uom: 'Boxes',
                article: {
                  name: 'Cloth Bundle'
                },
                sender: {
                  name: 'Sender 1',
                  mobile: '9876543212'
                },
                receiver: {
                  name: 'Receiver 1',
                  mobile: '9876543213'
                }
              }
            },
            {
              id: 'lr2',
              ogpl_id: 'ogpl1',
              booking_id: 'booking2',
              booking: {
                id: 'booking2',
                lr_number: 'LR-20250101-0002',
                quantity: 5,
                uom: 'Packages',
                article: {
                  name: 'Garments'
                },
                sender: {
                  name: 'Sender 2',
                  mobile: '9876543214'
                },
                receiver: {
                  name: 'Receiver 2',
                  mobile: '9876543215'
                }
              }
            }
          ]
        },
        {
          id: 'ogpl2',
          organization_id: organizationId,
          ogpl_number: 'OGPL-20250102-0001',
          name: 'Mumbai to Bangalore Transit',
          transit_mode: 'direct',
          transit_date: '2025-01-02',
          from_station: 'branch1',
          to_station: 'branch3',
          departure_time: '09:00',
          arrival_time: '20:00',
          supervisor_name: 'Amit Patel',
          supervisor_mobile: '9876543216',
          primary_driver_name: 'Ramesh Yadav',
          primary_driver_mobile: '9876543217',
          status: 'in_transit',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          vehicle: {
            id: 'vehicle2',
            vehicle_number: 'MH01CD5678',
            type: 'hired'
          },
          from_station_details: {
            id: 'branch1',
            name: 'Mumbai HQ',
            code: 'MUM-HQ'
          },
          to_station_details: {
            id: 'branch3',
            name: 'Bangalore Branch',
            code: 'BLR-01'
          },
          loading_records: [
            {
              id: 'lr3',
              ogpl_id: 'ogpl2',
              booking_id: 'booking3',
              booking: {
                id: 'booking3',
                lr_number: 'LR-20250102-0001',
                quantity: 10,
                uom: 'Bundles',
                article: {
                  name: 'Fabric Rolls'
                },
                sender: {
                  name: 'Sender 3',
                  mobile: '9876543218'
                },
                receiver: {
                  name: 'Receiver 3',
                  mobile: '9876543219'
                }
              }
            },
            {
              id: 'lr4',
              ogpl_id: 'ogpl2',
              booking_id: 'booking4',
              booking: {
                id: 'booking4',
                lr_number: 'LR-20250102-0002',
                quantity: 3,
                uom: 'Boxes',
                article: {
                  name: 'Textile Machinery'
                },
                sender: {
                  name: 'Sender 4',
                  mobile: '9876543220'
                },
                receiver: {
                  name: 'Receiver 4',
                  mobile: '9876543221'
                }
              }
            },
            {
              id: 'lr5',
              ogpl_id: 'ogpl2',
              booking_id: 'booking5',
              booking: {
                id: 'booking5',
                lr_number: 'LR-20250102-0003',
                quantity: 8,
                uom: 'Pieces',
                article: {
                  name: 'Garments'
                },
                sender: {
                  name: 'Sender 5',
                  mobile: '9876543222'
                },
                receiver: {
                  name: 'Receiver 5',
                  mobile: '9876543223'
                }
              }
            }
          ]
        }
      ];

      return mockOGPLs;
    } catch (err) {
      console.error('Failed to get incoming OGPLs:', err);
      setError(err instanceof Error ? err : new Error('Failed to get incoming OGPLs'));
      return [];
    } finally {
      setLoading(false);
    }
  };

  const unloadOGPL = async (
    ogplId: string, 
    bookingIds: string[], 
    conditions: Record<string, { status: string; remarks?: string; photo?: string }>
  ) => {
    try {
      setLoading(true);
      setError(null);

      console.log('Unloading OGPL:', ogplId);
      console.log('Booking IDs:', bookingIds);
      console.log('Conditions:', conditions);

      // Validate conditions
      const hasInvalidEntries = Object.entries(conditions).some(([bookingId, condition]) => {
        if (condition.status === 'damaged' && !condition.remarks) {
          showError('Validation Error', 'Please provide remarks for all damaged items');
          return true;
        }
        return false;
      });
      
      if (hasInvalidEntries) {
        throw new Error('Please provide remarks for all damaged items');
      }

      // In a real implementation, this would update the database
      // For demo purposes, we'll just simulate a delay
      await new Promise(resolve => setTimeout(resolve, 1500));

      // Update booking statuses to 'delivered'
      // In a real implementation, this would be done in the database
      
      showSuccess('Unloading Complete', 'All items have been successfully unloaded');
      return true;
    } catch (err) {
      console.error('Failed to unload OGPL:', err);
      setError(err instanceof Error ? err : new Error('Failed to unload OGPL'));
      showError('Unloading Failed', err instanceof Error ? err.message : 'Failed to unload OGPL');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getCompletedUnloadings = async () => {
    try {
      setLoading(true);
      setError(null);

      // In a real implementation, this would fetch from Supabase
      // For demo purposes, we'll create mock data
      const mockUnloadings = [
        {
          id: 'unloading1',
          ogpl_id: 'ogpl1',
          unloadedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(), // 2 days ago
          unloadedBy: 'John Doe',
          conditions: {
            'booking1': { status: 'good' },
            'booking2': { 
              status: 'damaged', 
              remarks: 'Package was crushed during transit. Contents partially damaged.',
              photo: 'https://images.unsplash.com/photo-1605792657660-596af9009e82?q=80&w=500&auto=format&fit=crop'
            }
          },
          ogpl: {
            id: 'ogpl1',
            ogpl_number: 'OGPL-20250101-0001',
            transit_date: '2025-01-01',
            from_station: { name: 'Mumbai HQ' },
            to_station: { name: 'Delhi Branch' },
            vehicle: { id: 'vehicle1', vehicle_number: 'MH01AB1234', type: 'own' },
            primary_driver_name: 'Sunil Sharma',
            primary_driver_mobile: '9876543211',
            loading_records: [
              {
                booking: {
                  id: 'booking1',
                  lr_number: 'LR-20250101-0001',
                  quantity: 2,
                  uom: 'Boxes',
                  article: { name: 'Cloth Bundle' },
                  sender: { name: 'Sender 1', mobile: '9876543212' },
                  receiver: { name: 'Receiver 1', mobile: '9876543213' }
                }
              },
              {
                booking: {
                  id: 'booking2',
                  lr_number: 'LR-20250101-0002',
                  quantity: 5,
                  uom: 'Packages',
                  article: { name: 'Garments' },
                  sender: { name: 'Sender 2', mobile: '9876543214' },
                  receiver: { name: 'Receiver 2', mobile: '9876543215' }
                }
              }
            ]
          }
        },
        {
          id: 'unloading2',
          ogpl_id: 'ogpl2',
          unloadedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(), // 5 days ago
          unloadedBy: 'Jane Smith',
          conditions: {
            'booking3': { status: 'good' },
            'booking4': { status: 'good' },
            'booking5': { 
              status: 'missing', 
              remarks: 'Package was not found during unloading. Investigation ongoing.'
            }
          },
          ogpl: {
            id: 'ogpl2',
            ogpl_number: 'OGPL-20250102-0001',
            transit_date: '2025-01-02',
            from_station: { name: 'Mumbai HQ' },
            to_station: { name: 'Bangalore Branch' },
            vehicle: { id: 'vehicle2', vehicle_number: 'MH01CD5678', type: 'hired' },
            primary_driver_name: 'Ramesh Yadav',
            primary_driver_mobile: '9876543217',
            loading_records: [
              {
                booking: {
                  id: 'booking3',
                  lr_number: 'LR-20250102-0001',
                  quantity: 10,
                  uom: 'Bundles',
                  article: { name: 'Fabric Rolls' },
                  sender: { name: 'Sender 3', mobile: '9876543218' },
                  receiver: { name: 'Receiver 3', mobile: '9876543219' }
                }
              },
              {
                booking: {
                  id: 'booking4',
                  lr_number: 'LR-20250102-0002',
                  quantity: 3,
                  uom: 'Boxes',
                  article: { name: 'Textile Machinery' },
                  sender: { name: 'Sender 4', mobile: '9876543220' },
                  receiver: { name: 'Receiver 4', mobile: '9876543221' }
                }
              },
              {
                booking: {
                  id: 'booking5',
                  lr_number: 'LR-20250102-0003',
                  quantity: 8,
                  uom: 'Pieces',
                  article: { name: 'Garments' },
                  sender: { name: 'Sender 5', mobile: '9876543222' },
                  receiver: { name: 'Receiver 5', mobile: '9876543223' }
                }
              }
            ]
          }
        }
      ];

      return mockUnloadings;
    } catch (err) {
      console.error('Failed to get completed unloadings:', err);
      setError(err instanceof Error ? err : new Error('Failed to get completed unloadings'));
      return [];
    } finally {
      setLoading(false);
    }
  };

  return {
    loading,
    error,
    getIncomingOGPLs,
    unloadOGPL,
    getCompletedUnloadings
  };
}