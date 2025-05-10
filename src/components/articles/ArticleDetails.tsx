import React, { useState, useEffect } from 'react';
import { 
  Package, 
  IndianRupee, 
  FileText, 
  Calendar, 
  Tag, 
  Edit, 
  Users, 
  Building2, 
  AlertTriangle, 
  ShieldCheck, 
  Truck, 
  BarChart3 
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useBookings } from '@/hooks/useBookings';
import { useCustomers } from '@/hooks/useCustomers';
import { useArticles } from '@/hooks/useArticles';
import { Badge } from '@/components/ui/badge';
import type { Article } from '@/types';

interface Props {
  article: Article;
  onClose: () => void;
  onEdit: () => void;
}

export default function ArticleDetails({ article, onClose, onEdit }: Props) {
  const [activeTab, setActiveTab] = useState('overview');
  const { bookings } = useBookings();
  const { customers } = useCustomers();
  const { getCustomerRates } = useArticles();
  const [customerRates, setCustomerRates] = useState<any[]>([]);

  // Filter bookings for this article
  const articleBookings = bookings.filter(booking => booking.article_id === article.id);

  // Load customer rates
  useEffect(() => {
    const loadCustomerRates = async () => {
      try {
        // In a real implementation, we would fetch all customer rates for this article
        // For demo purposes, we'll create mock data
        const mockRates = customers
          .filter((_, index) => index % 3 === 0) // Just use some customers for demo
          .map(customer => ({
            id: `rate-${customer.id}-${article.id}`,
            customer_id: customer.id,
            article_id: article.id,
            rate: article.base_rate * (0.8 + Math.random() * 0.3), // Random rate between 80% and 110% of base rate
            customer_name: customer.name,
            customer_type: customer.type
          }));
        
        setCustomerRates(mockRates);
      } catch (err) {
        console.error('Failed to load customer rates:', err);
      }
    };
    
    loadCustomerRates();
  }, [article.id, customers]);

  // Calculate statistics
  const stats = React.useMemo(() => {
    const totalBookings = articleBookings.length;
    const totalQuantity = articleBookings.reduce((sum, b) => sum + (b.quantity || 0), 0);
    const totalRevenue = articleBookings.reduce((sum, b) => sum + (b.total_amount || 0), 0);
    const avgRatePerBooking = totalBookings > 0 ? totalRevenue / totalBookings : 0;
    
    return {
      totalBookings,
      totalQuantity,
      totalRevenue,
      avgRatePerBooking
    };
  }, [articleBookings]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="h-12 w-12 rounded-xl bg-blue-100 flex items-center justify-center">
            <Package className="h-6 w-6 text-blue-600" />
          </div>
          <div>
            <h2 className="text-2xl font-bold text-gray-900">{article.name}</h2>
            {article.description && (
              <p className="text-gray-600 mt-1">{article.description}</p>
            )}
          </div>
        </div>
        <Button onClick={onEdit} className="flex items-center gap-2">
          <Edit className="h-4 w-4" />
          Edit Article
        </Button>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid grid-cols-3 mb-6">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="bookings">Bookings</TabsTrigger>
          <TabsTrigger value="rates">Customer Rates</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          {/* Basic Information */}
          <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Article Information</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-gray-600">Base Rate</p>
                  <div className="flex items-center gap-2 mt-1">
                    <IndianRupee className="h-4 w-4 text-gray-400" />
                    <p className="font-medium text-gray-900">₹{article.base_rate.toFixed(2)}</p>
                  </div>
                </div>
                
                {article.hsn_code && (
                  <div>
                    <p className="text-sm text-gray-600">HSN Code</p>
                    <div className="flex items-center gap-2 mt-1">
                      <FileText className="h-4 w-4 text-gray-400" />
                      <p className="font-medium text-gray-900">{article.hsn_code}</p>
                    </div>
                  </div>
                )}
                
                {article.tax_rate !== undefined && (
                  <div>
                    <p className="text-sm text-gray-600">Tax Rate</p>
                    <div className="flex items-center gap-2 mt-1">
                      <Tag className="h-4 w-4 text-gray-400" />
                      <p className="font-medium text-gray-900">{article.tax_rate}%</p>
                    </div>
                  </div>
                )}
                
                {article.unit_of_measure && (
                  <div>
                    <p className="text-sm text-gray-600">Unit of Measure</p>
                    <div className="flex items-center gap-2 mt-1">
                      <Package className="h-4 w-4 text-gray-400" />
                      <p className="font-medium text-gray-900 capitalize">{article.unit_of_measure}</p>
                    </div>
                  </div>
                )}
              </div>
              
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-gray-600">Branch</p>
                  <div className="flex items-center gap-2 mt-1">
                    <Building2 className="h-4 w-4 text-gray-400" />
                    <p className="font-medium text-gray-900">{article.branch_name || 'Unknown Branch'}</p>
                  </div>
                </div>
                
                <div>
                  <p className="text-sm text-gray-600">Created On</p>
                  <div className="flex items-center gap-2 mt-1">
                    <Calendar className="h-4 w-4 text-gray-400" />
                    <p className="font-medium text-gray-900">{new Date(article.created_at).toLocaleDateString()}</p>
                  </div>
                </div>
                
                <div className="flex flex-wrap gap-2">
                  {article.is_fragile && (
                    <div className="flex items-center gap-1 px-2 py-1 bg-yellow-100 rounded-lg text-yellow-800 text-xs">
                      <AlertTriangle className="h-3 w-3" />
                      <span>Fragile</span>
                    </div>
                  )}
                  
                  {article.requires_special_handling && (
                    <div className="flex items-center gap-1 px-2 py-1 bg-purple-100 rounded-lg text-purple-800 text-xs">
                      <ShieldCheck className="h-3 w-3" />
                      <span>Special Handling</span>
                    </div>
                  )}
                  
                  {article.min_quantity > 1 && (
                    <div className="flex items-center gap-1 px-2 py-1 bg-blue-100 rounded-lg text-blue-800 text-xs">
                      <Package className="h-3 w-3" />
                      <span>Min Qty: {article.min_quantity}</span>
                    </div>
                  )}
                </div>
              </div>
            </div>
            
            {article.notes && (
              <div className="mt-6 p-4 bg-gray-50 rounded-lg">
                <p className="text-sm font-medium text-gray-700">Additional Notes</p>
                <p className="text-sm text-gray-600 mt-1">{article.notes}</p>
              </div>
            )}
          </div>
          
          {/* Statistics */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div className="bg-blue-50 rounded-xl p-6 border border-blue-100">
              <h4 className="text-sm font-medium text-blue-700 mb-2">Total Bookings</h4>
              <p className="text-3xl font-bold text-blue-900">{stats.totalBookings}</p>
              <p className="text-sm text-blue-600 mt-2">
                Lifetime bookings with this article
              </p>
            </div>
            
            <div className="bg-green-50 rounded-xl p-6 border border-green-100">
              <h4 className="text-sm font-medium text-green-700 mb-2">Total Quantity</h4>
              <p className="text-3xl font-bold text-green-900">{stats.totalQuantity}</p>
              <p className="text-sm text-green-600 mt-2">
                Units shipped
              </p>
            </div>
            
            <div className="bg-purple-50 rounded-xl p-6 border border-purple-100">
              <h4 className="text-sm font-medium text-purple-700 mb-2">Total Revenue</h4>
              <p className="text-3xl font-bold text-purple-900">₹{stats.totalRevenue.toLocaleString()}</p>
              <p className="text-sm text-purple-600 mt-2">
                Generated from all bookings
              </p>
            </div>
            
            <div className="bg-yellow-50 rounded-xl p-6 border border-yellow-100">
              <h4 className="text-sm font-medium text-yellow-700 mb-2">Avg. Rate</h4>
              <p className="text-3xl font-bold text-yellow-900">₹{stats.avgRatePerBooking.toFixed(2)}</p>
              <p className="text-sm text-yellow-600 mt-2">
                Average rate per booking
              </p>
            </div>
          </div>
          
          {/* Recent Bookings */}
          <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900">Recent Bookings</h3>
              <Button 
                variant="outline" 
                size="sm" 
                onClick={() => setActiveTab('bookings')}
                className="flex items-center gap-1"
              >
                View All
              </Button>
            </div>
            
            {articleBookings.length > 0 ? (
              <div className="space-y-4">
                {articleBookings.slice(0, 3).map((booking) => (
                  <div key={booking.id} className="flex items-start gap-4 p-4 bg-gray-50 rounded-lg">
                    <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                      <Truck className="h-5 w-5 text-blue-600" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <h4 className="font-medium text-gray-900">LR #{booking.lr_number}</h4>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          booking.status === 'delivered'
                            ? 'bg-green-100 text-green-800'
                            : booking.status === 'in_transit'
                            ? 'bg-blue-100 text-blue-800'
                            : booking.status === 'cancelled'
                            ? 'bg-red-100 text-red-800'
                            : 'bg-yellow-100 text-yellow-800'
                        }`}>
                          {booking.status.replace('_', ' ')}
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mt-1">
                        {booking.quantity} {booking.uom} • ₹{booking.total_amount}
                      </p>
                      <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
                        <div className="flex items-center gap-1">
                          <Calendar className="h-3.5 w-3.5" />
                          <span>{new Date(booking.created_at).toLocaleDateString()}</span>
                        </div>
                        <div className="flex items-center gap-1">
                          <Users className="h-3.5 w-3.5" />
                          <span>{booking.sender?.name} → {booking.receiver?.name}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8">
                <Package className="h-12 w-12 text-gray-300 mx-auto mb-3" />
                <h4 className="text-lg font-medium text-gray-900">No bookings yet</h4>
                <p className="text-gray-500 mt-1">This article hasn't been used in any bookings yet</p>
              </div>
            )}
          </div>
        </TabsContent>

        <TabsContent value="bookings" className="space-y-6">
          <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
            <div className="p-6 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Booking History</h3>
              <p className="text-gray-600 mt-1">All bookings using this article</p>
            </div>
            
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50">
                    <th className="text-left text-sm font-medium text-gray-600 px-6 py-4">LR Number</th>
                    <th className="text-left text-sm font-medium text-gray-600 px-6 py-4">Date</th>
                    <th className="text-left text-sm font-medium text-gray-600 px-6 py-4">Route</th>
                    <th className="text-left text-sm font-medium text-gray-600 px-6 py-4">Sender</th>
                    <th className="text-left text-sm font-medium text-gray-600 px-6 py-4">Receiver</th>
                    <th className="text-left text-sm font-medium text-gray-600 px-6 py-4">Quantity</th>
                    <th className="text-left text-sm font-medium text-gray-600 px-6 py-4">Status</th>
                    <th className="text-right text-sm font-medium text-gray-600 px-6 py-4">Amount</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {articleBookings.length > 0 ? (
                    articleBookings.map((booking) => (
                      <tr key={booking.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4">
                          <span className="font-medium text-blue-600">{booking.lr_number}</span>
                        </td>
                        <td className="px-6 py-4 text-sm">
                          {new Date(booking.created_at).toLocaleDateString()}
                        </td>
                        <td className="px-6 py-4 text-sm">
                          {booking.from_branch_details?.name} → {booking.to_branch_details?.name}
                        </td>
                        <td className="px-6 py-4 text-sm">
                          {booking.sender?.name || 'Unknown'}
                        </td>
                        <td className="px-6 py-4 text-sm">
                          {booking.receiver?.name || 'Unknown'}
                        </td>
                        <td className="px-6 py-4 text-sm">
                          {booking.quantity} {booking.uom}
                        </td>
                        <td className="px-6 py-4">
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            booking.status === 'delivered'
                              ? 'bg-green-100 text-green-800'
                              : booking.status === 'in_transit'
                              ? 'bg-blue-100 text-blue-800'
                              : booking.status === 'cancelled'
                              ? 'bg-red-100 text-red-800'
                              : 'bg-yellow-100 text-yellow-800'
                          }`}>
                            {booking.status.replace('_', ' ')}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right">
                          <div>
                            <div className="font-medium">₹{booking.total_amount}</div>
                            <div className="text-xs text-gray-500">{booking.payment_type}</div>
                          </div>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={8} className="px-6 py-8 text-center text-gray-500">
                        <Package className="h-12 w-12 text-gray-300 mx-auto mb-3" />
                        <h4 className="text-lg font-medium text-gray-900">No bookings found</h4>
                        <p className="text-gray-500 mt-1">This article hasn't been used in any bookings yet</p>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="rates" className="space-y-6">
          <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-medium text-gray-900">Customer-Specific Rates</h3>
                  <p className="text-gray-600 mt-1">Special pricing for specific customers</p>
                </div>
              </div>
            </div>
            
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50">
                    <th className="text-left text-sm font-medium text-gray-600 px-6 py-4">Customer</th>
                    <th className="text-left text-sm font-medium text-gray-600 px-6 py-4">Type</th>
                    <th className="text-right text-sm font-medium text-gray-600 px-6 py-4">Base Rate</th>
                    <th className="text-right text-sm font-medium text-gray-600 px-6 py-4">Custom Rate</th>
                    <th className="text-right text-sm font-medium text-gray-600 px-6 py-4">Discount</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {customerRates.length > 0 ? (
                    customerRates.map((rate) => {
                      const discount = ((article.base_rate - rate.rate) / article.base_rate) * 100;
                      
                      return (
                        <tr key={rate.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4">
                            <div className="flex items-center gap-3">
                              <div className={`h-8 w-8 rounded-full flex items-center justify-center ${
                                rate.customer_type === 'individual' 
                                  ? 'bg-blue-100 text-blue-600' 
                                  : 'bg-purple-100 text-purple-600'
                              }`}>
                                {rate.customer_type === 'individual' ? (
                                  <Users className="h-4 w-4" />
                                ) : (
                                  <Building2 className="h-4 w-4" />
                                )}
                              </div>
                              <span className="font-medium">{rate.customer_name}</span>
                            </div>
                          </td>
                          <td className="px-6 py-4">
                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                              rate.customer_type === 'individual'
                                ? 'bg-blue-100 text-blue-800'
                                : 'bg-purple-100 text-purple-800'
                            }`}>
                              {rate.customer_type}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-right">
                            ₹{article.base_rate.toFixed(2)}
                          </td>
                          <td className="px-6 py-4 text-right font-medium">
                            ₹{rate.rate.toFixed(2)}
                          </td>
                          <td className="px-6 py-4 text-right">
                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                              discount > 0
                                ? 'bg-green-100 text-green-800'
                                : discount < 0
                                ? 'bg-red-100 text-red-800'
                                : 'bg-gray-100 text-gray-800'
                            }`}>
                              {discount > 0 ? '-' : discount < 0 ? '+' : ''}
                              {Math.abs(discount).toFixed(1)}%
                            </span>
                          </td>
                        </tr>
                      );
                    })
                  ) : (
                    <tr>
                      <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                        <Tag className="h-12 w-12 text-gray-300 mx-auto mb-3" />
                        <h4 className="text-lg font-medium text-gray-900">No custom rates</h4>
                        <p className="text-gray-500 mt-1">No customers have special pricing for this article</p>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}