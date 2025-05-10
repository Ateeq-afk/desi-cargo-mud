import React, { useState, useEffect } from 'react';
import { Tag, Search, ArrowUpDown, Plus, Minus, Save, X, Loader2, AlertCircle, CheckCircle2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useArticles } from '@/hooks/useArticles';
import { useCustomers } from '@/hooks/useCustomers';
import { useNotificationSystem } from '@/hooks/useNotificationSystem';

interface Props {
  onClose: () => void;
}

export default function ArticleBulkRates({ onClose }: Props) {
  const [searchQuery, setSearchQuery] = useState('');
  const [customerFilter, setCustomerFilter] = useState<string>('all');
  const [adjustmentType, setAdjustmentType] = useState<'percentage' | 'fixed'>('percentage');
  const [adjustmentValue, setAdjustmentValue] = useState<number>(0);
  const [selectedArticles, setSelectedArticles] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [step, setStep] = useState<'select' | 'adjust' | 'preview' | 'complete'>('select');
  const [previewData, setPreviewData] = useState<any[]>([]);

  const { articles, updateArticle } = useArticles();
  const { customers } = useCustomers();
  const { showSuccess, showError } = useNotificationSystem();

  // Filter articles based on search
  const filteredArticles = React.useMemo(() => {
    return articles.filter(article => 
      article.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (article.description && article.description.toLowerCase().includes(searchQuery.toLowerCase()))
    );
  }, [articles, searchQuery]);

  const toggleArticleSelection = (articleId: string) => {
    setSelectedArticles(prev => 
      prev.includes(articleId)
        ? prev.filter(id => id !== articleId)
        : [...prev, articleId]
    );
  };

  const selectAllArticles = () => {
    if (selectedArticles.length === filteredArticles.length) {
      setSelectedArticles([]);
    } else {
      setSelectedArticles(filteredArticles.map(article => article.id));
    }
  };

  const handleNextStep = () => {
    if (step === 'select') {
      if (selectedArticles.length === 0) {
        showError('Selection Required', 'Please select at least one article');
        return;
      }
      setStep('adjust');
    } else if (step === 'adjust') {
      generatePreview();
      setStep('preview');
    }
  };

  const handlePreviousStep = () => {
    if (step === 'adjust') {
      setStep('select');
    } else if (step === 'preview') {
      setStep('adjust');
    }
  };

  const generatePreview = () => {
    const preview = selectedArticles.map(articleId => {
      const article = articles.find(a => a.id === articleId);
      if (!article) return null;
      
      let newRate;
      if (adjustmentType === 'percentage') {
        newRate = article.base_rate * (1 + adjustmentValue / 100);
      } else {
        newRate = article.base_rate + adjustmentValue;
      }
      
      // Ensure rate is not negative
      newRate = Math.max(0, newRate);
      
      return {
        id: article.id,
        name: article.name,
        description: article.description,
        currentRate: article.base_rate,
        newRate,
        change: newRate - article.base_rate,
        percentChange: ((newRate - article.base_rate) / article.base_rate) * 100
      };
    }).filter(Boolean);
    
    setPreviewData(preview);
  };

  const handleApplyChanges = async () => {
    try {
      setLoading(true);
      
      // Update each article
      for (const item of previewData) {
        await updateArticle(item.id, { base_rate: item.newRate });
      }
      
      setStep('complete');
      setTimeout(() => {
        showSuccess('Rates Updated', `Successfully updated rates for ${previewData.length} articles`);
        onClose();
      }, 2000);
    } catch (err) {
      console.error('Failed to update rates:', err);
      showError('Update Failed', 'Failed to update article rates');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-900">Bulk Rate Management</h2>
          <p className="text-gray-600 mt-1">Update rates for multiple articles at once</p>
        </div>
        <Button variant="ghost" size="icon" onClick={onClose}>
          <X className="h-5 w-5" />
        </Button>
      </div>

      {step === 'select' && (
        <>
          <div className="space-y-4">
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                <Input
                  className="pl-10"
                  placeholder="Search articles..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
              <Button 
                variant="outline" 
                onClick={selectAllArticles}
                className="whitespace-nowrap"
              >
                {selectedArticles.length === filteredArticles.length ? 'Deselect All' : 'Select All'}
              </Button>
            </div>

            <div className="bg-white border border-gray-200 rounded-lg">
              <div className="p-4 border-b border-gray-200 bg-gray-50">
                <div className="flex items-center justify-between">
                  <h3 className="font-medium text-gray-900">Select Articles ({selectedArticles.length} selected)</h3>
                </div>
              </div>
              <div className="overflow-x-auto max-h-[400px]">
                <table className="w-full">
                  <thead className="bg-gray-50 sticky top-0">
                    <tr>
                      <th className="w-12 px-4 py-2">
                        <input
                          type="checkbox"
                          checked={selectedArticles.length === filteredArticles.length && filteredArticles.length > 0}
                          onChange={selectAllArticles}
                          className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        />
                      </th>
                      <th 
                        className="text-left text-xs font-medium text-gray-500 uppercase px-4 py-2 cursor-pointer"
                        onClick={() => {/* Add sorting logic */}}
                      >
                        <div className="flex items-center gap-1">
                          Name
                          <ArrowUpDown className="h-3 w-3" />
                        </div>
                      </th>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase px-4 py-2">Description</th>
                      <th 
                        className="text-right text-xs font-medium text-gray-500 uppercase px-4 py-2 cursor-pointer"
                        onClick={() => {/* Add sorting logic */}}
                      >
                        <div className="flex items-center justify-end gap-1">
                          Base Rate
                          <ArrowUpDown className="h-3 w-3" />
                        </div>
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {filteredArticles.length > 0 ? (
                      filteredArticles.map((article) => (
                        <tr key={article.id} className="hover:bg-gray-50">
                          <td className="px-4 py-2 text-center">
                            <input
                              type="checkbox"
                              checked={selectedArticles.includes(article.id)}
                              onChange={() => toggleArticleSelection(article.id)}
                              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                            />
                          </td>
                          <td className="px-4 py-2 text-sm font-medium">{article.name}</td>
                          <td className="px-4 py-2 text-sm text-gray-600">{article.description || '-'}</td>
                          <td className="px-4 py-2 text-sm text-right font-medium">₹{article.base_rate.toFixed(2)}</td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={4} className="px-4 py-8 text-center text-gray-500">
                          <AlertCircle className="h-8 w-8 text-gray-300 mx-auto mb-2" />
                          <p>No articles found matching your search</p>
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-3">
            <Button variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button 
              onClick={handleNextStep} 
              disabled={selectedArticles.length === 0}
            >
              Next: Adjust Rates
            </Button>
          </div>
        </>
      )}

      {step === 'adjust' && (
        <>
          <div className="space-y-6">
            <div className="bg-blue-50 border border-blue-100 rounded-lg p-4 flex items-start gap-3">
              <Tag className="h-5 w-5 text-blue-500 shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-blue-800 font-medium">Rate Adjustment</p>
                <p className="text-blue-600 text-sm mt-1">
                  You are about to adjust rates for {selectedArticles.length} articles.
                  Choose how you want to modify the rates below.
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <Label>Adjustment Type</Label>
                <Select 
                  value={adjustmentType} 
                  onValueChange={(value: 'percentage' | 'fixed') => setAdjustmentType(value)}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select adjustment type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="percentage">Percentage Change</SelectItem>
                    <SelectItem value="fixed">Fixed Amount Change</SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-sm text-gray-500 mt-1">
                  {adjustmentType === 'percentage' 
                    ? 'Adjust rates by a percentage (e.g., +10% or -5%)' 
                    : 'Add or subtract a fixed amount (e.g., +₹50 or -₹20)'}
                </p>
              </div>

              <div>
                <Label>Adjustment Value</Label>
                <div className="flex items-center">
                  <Button
                    type="button"
                    variant="outline"
                    size="icon"
                    className="rounded-r-none h-10"
                    onClick={() => setAdjustmentValue(prev => prev - (adjustmentType === 'percentage' ? 5 : 10))}
                  >
                    <Minus className="h-4 w-4" />
                  </Button>
                  <div className="relative flex-1">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">
                      {adjustmentType === 'percentage' ? '%' : '₹'}
                    </span>
                    <Input
                      type="number"
                      value={adjustmentValue}
                      onChange={(e) => setAdjustmentValue(parseFloat(e.target.value) || 0)}
                      className="rounded-none pl-8 text-center"
                    />
                  </div>
                  <Button
                    type="button"
                    variant="outline"
                    size="icon"
                    className="rounded-l-none h-10"
                    onClick={() => setAdjustmentValue(prev => prev + (adjustmentType === 'percentage' ? 5 : 10))}
                  >
                    <Plus className="h-4 w-4" />
                  </Button>
                </div>
                <p className="text-sm text-gray-500 mt-1">
                  {adjustmentValue > 0 
                    ? `Increase rates by ${adjustmentType === 'percentage' ? adjustmentValue + '%' : '₹' + adjustmentValue}` 
                    : adjustmentValue < 0 
                    ? `Decrease rates by ${adjustmentType === 'percentage' ? Math.abs(adjustmentValue) + '%' : '₹' + Math.abs(adjustmentValue)}` 
                    : 'No change to rates'}
                </p>
              </div>
            </div>

            <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
              <h3 className="font-medium text-gray-900 mb-2">Example Calculation</h3>
              <div className="space-y-2">
                <div className="flex items-center justify-between text-sm">
                  <span>Current Rate:</span>
                  <span className="font-medium">₹100.00</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span>Adjustment:</span>
                  <span className={`font-medium ${adjustmentValue > 0 ? 'text-green-600' : adjustmentValue < 0 ? 'text-red-600' : ''}`}>
                    {adjustmentValue > 0 ? '+' : ''}
                    {adjustmentType === 'percentage' 
                      ? `${adjustmentValue}% (₹${(100 * adjustmentValue / 100).toFixed(2)})` 
                      : `₹${adjustmentValue.toFixed(2)}`}
                  </span>
                </div>
                <div className="flex items-center justify-between text-sm font-medium border-t border-gray-300 pt-2">
                  <span>New Rate:</span>
                  <span>
                    ₹{adjustmentType === 'percentage' 
                      ? (100 * (1 + adjustmentValue / 100)).toFixed(2) 
                      : (100 + adjustmentValue).toFixed(2)}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div className="flex justify-between gap-3">
            <Button variant="outline" onClick={handlePreviousStep}>
              Back: Select Articles
            </Button>
            <Button onClick={handleNextStep}>
              Next: Preview Changes
            </Button>
          </div>
        </>
      )}

      {step === 'preview' && (
        <>
          <div className="space-y-6">
            <div className="bg-yellow-50 border border-yellow-100 rounded-lg p-4 flex items-start gap-3">
              <AlertCircle className="h-5 w-5 text-yellow-500 shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-yellow-800 font-medium">Review Changes</p>
                <p className="text-yellow-600 text-sm mt-1">
                  Please review the rate changes below before applying them.
                  This action will update the base rates for all selected articles.
                </p>
              </div>
            </div>

            <div className="bg-white border border-gray-200 rounded-lg">
              <div className="p-4 border-b border-gray-200 bg-gray-50">
                <h3 className="font-medium text-gray-900">Rate Changes Preview</h3>
              </div>
              <div className="overflow-x-auto max-h-[400px]">
                <table className="w-full">
                  <thead className="bg-gray-50 sticky top-0">
                    <tr>
                      <th className="text-left text-xs font-medium text-gray-500 uppercase px-4 py-2">Article</th>
                      <th className="text-right text-xs font-medium text-gray-500 uppercase px-4 py-2">Current Rate</th>
                      <th className="text-right text-xs font-medium text-gray-500 uppercase px-4 py-2">New Rate</th>
                      <th className="text-right text-xs font-medium text-gray-500 uppercase px-4 py-2">Change</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {previewData.map((item) => (
                      <tr key={item.id} className="hover:bg-gray-50">
                        <td className="px-4 py-2 text-sm">
                          <div className="font-medium">{item.name}</div>
                          {item.description && (
                            <div className="text-xs text-gray-500">{item.description}</div>
                          )}
                        </td>
                        <td className="px-4 py-2 text-sm text-right">₹{item.currentRate.toFixed(2)}</td>
                        <td className="px-4 py-2 text-sm text-right font-medium">₹{item.newRate.toFixed(2)}</td>
                        <td className="px-4 py-2 text-sm text-right">
                          <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                            item.change > 0
                              ? 'bg-green-100 text-green-800'
                              : item.change < 0
                              ? 'bg-red-100 text-red-800'
                              : 'bg-gray-100 text-gray-800'
                          }`}>
                            {item.change > 0 ? '+' : ''}
                            {item.change.toFixed(2)} ({item.percentChange > 0 ? '+' : ''}
                            {item.percentChange.toFixed(1)}%)
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div className="flex justify-between gap-3">
            <Button variant="outline" onClick={handlePreviousStep}>
              Back: Adjust Rates
            </Button>
            <Button 
              onClick={handleApplyChanges} 
              disabled={loading}
              className="flex items-center gap-2"
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Applying Changes...
                </>
              ) : (
                <>
                  <Save className="h-4 w-4" />
                  Apply Changes
                </>
              )}
            </Button>
          </div>
        </>
      )}

      {step === 'complete' && (
        <div className="py-12 flex flex-col items-center justify-center">
          <CheckCircle2 className="h-12 w-12 text-green-600 mb-4" />
          <h3 className="text-lg font-medium text-gray-900">Changes Applied</h3>
          <p className="text-gray-500 mt-1">Successfully updated rates for {previewData.length} articles</p>
        </div>
      )}
    </div>
  );
}