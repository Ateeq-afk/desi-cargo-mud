import { useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import type { OGPL, Booking } from '@/types';

export function useOGPL(organizationId: string | null) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const generateOGPLNumber = async () => {
    try {
      // Get the latest OGPL number for the organization
      const { data: latest, error: queryError } = await supabase
        .from('ogpl')
        .select('ogpl_number')
        .eq('organization_id', organizationId)
        .order('created_at', { ascending: false })
        .limit(1);

      if (queryError) throw queryError;

      // Generate new OGPL number
      // Format: OGPL-YYYYMMDD-XXXX
      const date = new Date();
      const dateStr = date.getFullYear().toString() +
        (date.getMonth() + 1).toString().padStart(2, '0') +
        date.getDate().toString().padStart(2, '0');

      let sequence = 1;
      if (latest?.[0]?.ogpl_number) {
        const lastSequence = parseInt(latest[0].ogpl_number.split('-')[2]);
        sequence = lastSequence + 1;
      }

      return `OGPL-${dateStr}-${sequence.toString().padStart(4, '0')}`;
    } catch (err) {
      throw err instanceof Error ? err : new Error('Failed to generate OGPL number');
    }
  };

  const createOGPL = async (data: Omit<OGPL, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      setLoading(true);
      setError(null);

      // Generate OGPL number if not provided
      if (!data.ogpl_number) {
        data.ogpl_number = await generateOGPLNumber();
      }

      // In a real implementation, this would create an OGPL in the database
      // For demo purposes, we'll create a mock OGPL
      const mockOGPL: OGPL = {
        id: Math.random().toString(36).substring(2, 15),
        ...data,
        organization_id: organizationId || '',
        status: 'created',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        vehicle: {
          id: data.vehicle_id,
          vehicle_number: 'MH01AB1234', // Mock data
          type: 'own' // Mock data
        },
        from_station_details: {
          id: data.from_station,
          name: 'Mumbai HQ', // Mock data
          code: 'MUM-HQ' // Mock data
        } as Branch,
        to_station_details: {
          id: data.to_station,
          name: 'Delhi Branch', // Mock data
          code: 'DEL-01' // Mock data
        } as Branch
      };

      console.log('Created OGPL:', mockOGPL);
      return mockOGPL;

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to create OGPL'));
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const addLRsToOGPL = async (ogplId: string, bookingIds: string[]) => {
    try {
      setLoading(true);
      setError(null);

      // In a real implementation, this would create loading records in the database
      // For demo purposes, we'll create mock loading records
      const mockLoadingRecords = bookingIds.map(bookingId => ({
        id: Math.random().toString(36).substring(2, 15),
        ogpl_id: ogplId,
        booking_id: bookingId,
        loaded_at: new Date().toISOString(),
        loaded_by: 'user1', // This would be the current user's ID
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }));

      console.log('Added LRs to OGPL:', mockLoadingRecords);
      return mockLoadingRecords;

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to add LRs to OGPL'));
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const updateOGPLStatus = async (id: string, status: OGPL['status']) => {
    try {
      setLoading(true);
      setError(null);

      // In a real implementation, this would update the OGPL status in the database
      // For demo purposes, we'll just log the update
      console.log(`Updated OGPL ${id} status to ${status}`);
      
      return {
        id,
        status,
        updated_at: new Date().toISOString()
      };

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to update OGPL status'));
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getOGPLs = async () => {
    try {
      setLoading(true);
      setError(null);

      // In a real implementation, this would fetch from the database
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
            }
          ]
        }
      ];

      return mockOGPLs;

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to get OGPLs'));
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getOGPLDetails = async (id: string) => {
    try {
      setLoading(true);
      setError(null);

      // In a real implementation, this would fetch from the database
      // For demo purposes, we'll create mock data
      const mockOGPL = {
        id,
        organization_id: organizationId,
        ogpl_number: `OGPL-${id.substring(0, 8)}`,
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
            ogpl_id: id,
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
            ogpl_id: id,
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
      };

      return mockOGPL;

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to get OGPL details'));
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getOGPLLRs = async (ogplId: string) => {
    try {
      setLoading(true);
      setError(null);

      // In a real implementation, this would fetch loading records from the database
      // For demo purposes, we'll create mock loading records
      const mockLoadingRecords = [
        {
          id: 'lr1',
          ogpl_id: ogplId,
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
          ogpl_id: ogplId,
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
      ];

      return mockLoadingRecords;

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to get OGPL LRs'));
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return {
    loading,
    error,
    createOGPL,
    addLRsToOGPL,
    updateOGPLStatus,
    getOGPLs,
    getOGPLDetails,
    getOGPLLRs,
    generateOGPLNumber
  };
}