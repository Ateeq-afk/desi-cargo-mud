import React, { useState } from 'react';
import { Plus, Package, MoreVertical, AlertCircle, Edit, Trash, Search, Filter, Download, Upload, ArrowUpDown, Tag, RefreshCw } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
} from '@/components/ui/dropdown-menu';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useArticles } from '@/hooks/useArticles';
import { useBranches } from '@/hooks/useBranches';
import { useNotificationSystem } from '@/hooks/useNotificationSystem';
import ArticleForm from './ArticleForm';
import ArticleDetails from './ArticleDetails';
import ArticleImport from './ArticleImport';
import ArticleExport from './ArticleExport';
import ArticleBulkRates from './ArticleBulkRates';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';

export default function ArticleList() {
  const [showForm, setShowForm] = useState(false);
  const [editingArticle, setEditingArticle] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [articleToDelete, setArticleToDelete] = useState<string | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [showDetails, setShowDetails] = useState<string | null>(null);
  const [showImport, setShowImport] = useState(false);
  const [showExport, setShowExport] = useState(false);
  const [showBulkRates, setShowBulkRates] = useState(false);
  const [branchFilter, setBranchFilter] = useState<string>('all');
  const [sortField, setSortField] = useState<string>('name');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 12;

  const { articles, loading, error, createArticle, updateArticle, deleteArticle, refresh } = useArticles();
  const { branches } = useBranches();
  const { showSuccess, showError } = useNotificationSystem();

  // Apply filters and sorting
  const filteredArticles = React.useMemo(() => {
    return articles.filter(article => {
      // Search filter
      const matchesSearch = 
        article.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (article.description && article.description.toLowerCase().includes(searchQuery.toLowerCase()));
      
      // Branch filter
      const matchesBranch = branchFilter === 'all' || article.branch_id === branchFilter;
      
      return matchesSearch && matchesBranch;
    }).sort((a, b) => {
      // Sorting
      if (sortField === 'name') {
        return sortDirection === 'asc' 
          ? a.name.localeCompare(b.name)
          : b.name.localeCompare(a.name);
      } else if (sortField === 'base_rate') {
        return sortDirection === 'asc'
          ? a.base_rate - b.base_rate
          : b.base_rate - a.base_rate;
      } else if (sortField === 'created_at') {
        return sortDirection === 'asc'
          ? new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
          : new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
      }
      return 0;
    });
  }, [articles, searchQuery, branchFilter, sortField, sortDirection]);

  // Pagination
  const totalPages = Math.ceil(filteredArticles.length / itemsPerPage);
  const paginatedArticles = filteredArticles.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const handleCreateArticle = async (data) => {
    try {
      await createArticle(data);
      setShowForm(false);
      showSuccess('Article Created', 'Article has been successfully created');
    } catch (err) {
      console.error('Failed to create article:', err);
      showError('Creation Failed', 'Failed to create article');
    }
  };

  const handleUpdateArticle = async (data) => {
    if (!editingArticle) return;
    
    try {
      await updateArticle(editingArticle.id, data);
      setEditingArticle(null);
      setShowForm(false);
      showSuccess('Article Updated', 'Article has been successfully updated');
    } catch (err) {
      console.error('Failed to update article:', err);
      showError('Update Failed', 'Failed to update article');
    }
  };

  const handleDeleteArticle = async () => {
    if (!articleToDelete) return;

    try {
      setDeleteError(null);
      await deleteArticle(articleToDelete);
      setArticleToDelete(null);
      showSuccess('Article Deleted', 'Article has been successfully deleted');
    } catch (err) {
      console.error('Failed to delete article:', err);
      setDeleteError(err instanceof Error ? err.message : 'Failed to delete article');
    }
  };

  const handleSort = (field: string) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };

  const handleRefresh = async () => {
    try {
      await refresh();
      showSuccess('Refreshed', 'Article list has been refreshed');
    } catch (err) {
      showError('Refresh Failed', 'Failed to refresh article list');
    }
  };

  const handleImportSuccess = () => {
    setShowImport(false);
    refresh();
    showSuccess('Import Successful', 'Articles have been imported successfully');
  };

  const handleExportSuccess = () => {
    setShowExport(false);
    showSuccess('Export Successful', 'Articles have been exported successfully');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 p-6 flex items-center justify-center">
        <div className="flex items-center gap-2 text-blue-600">
          <div className="animate-spin h-5 w-5 border-2 border-current border-t-transparent rounded-full"></div>
          <span>Loading articles...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 p-6 flex items-center justify-center">
        <div className="flex items-center gap-2 text-red-600">
          <AlertCircle className="h-5 w-5" />
          <span>Failed to load articles. Please try again.</span>
        </div>
      </div>
    );
  }

  if (showForm) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 p-6">
        <div className="max-w-3xl mx-auto">
          <ArticleForm
            onSubmit={editingArticle ? handleUpdateArticle : handleCreateArticle}
            onCancel={() => {
              setShowForm(false);
              setEditingArticle(null);
            }}
            initialData={editingArticle || undefined}
          />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Articles</h2>
          <p className="text-gray-600 mt-1">
            {filteredArticles.length} articles found
          </p>
        </div>
        <div className="flex flex-wrap gap-3">
          <Button variant="outline" onClick={handleRefresh} className="flex items-center gap-2">
            <RefreshCw className="h-4 w-4" />
            Refresh
          </Button>
          <Button variant="outline" onClick={() => setShowImport(true)} className="flex items-center gap-2">
            <Upload className="h-4 w-4" />
            Import
          </Button>
          <Button variant="outline" onClick={() => setShowExport(true)} className="flex items-center gap-2">
            <Download className="h-4 w-4" />
            Export
          </Button>
          <Button variant="outline" onClick={() => setShowBulkRates(true)} className="flex items-center gap-2">
            <Tag className="h-4 w-4" />
            Bulk Rates
          </Button>
          <Button onClick={() => setShowForm(true)} className="flex items-center gap-2">
            <Plus className="h-5 w-5" />
            Add Article
          </Button>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
              <Input
                className="pl-10"
                placeholder="Search articles by name or description..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            
            <Select value={branchFilter} onValueChange={setBranchFilter}>
              <SelectTrigger>
                <SelectValue placeholder="Filter by branch" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Branches</SelectItem>
                {branches.map((branch) => (
                  <SelectItem key={branch.id} value={branch.id}>
                    {branch.name} - {branch.city}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6">
          {paginatedArticles.map((article) => (
            <div key={article.id} className="bg-white rounded-xl border border-gray-200 p-6 hover:shadow-md transition-shadow">
              <div className="flex items-start justify-between">
                <div 
                  className="flex items-start gap-4 cursor-pointer"
                  onClick={() => setShowDetails(article.id)}
                >
                  <div className="h-12 w-12 rounded-xl bg-blue-100 flex items-center justify-center">
                    <Package className="h-6 w-6 text-blue-600" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-900 hover:text-blue-600">{article.name}</h3>
                    {article.description && (
                      <p className="text-sm text-gray-500 mt-1">{article.description}</p>
                    )}
                    <div className="mt-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      ₹{article.base_rate.toFixed(2)} base rate
                    </div>
                  </div>
                </div>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="icon">
                      <MoreVertical className="h-5 w-5" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onClick={() => setShowDetails(article.id)}>
                      <Package className="h-4 w-4 mr-2" />
                      View Details
                    </DropdownMenuItem>
                    <DropdownMenuItem onClick={() => {
                      setEditingArticle(article);
                      setShowForm(true);
                    }}>
                      <Edit className="h-4 w-4 mr-2" />
                      Edit Article
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem 
                      className="text-red-600"
                      onClick={() => setArticleToDelete(article.id)}
                    >
                      <Trash className="h-4 w-4 mr-2" />
                      Delete Article
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </div>
          ))}

          {paginatedArticles.length === 0 && (
            <div className="col-span-full text-center py-12">
              <Package className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900">No articles found</h3>
              <p className="text-gray-600 mt-1">
                {searchQuery || branchFilter !== 'all' 
                  ? 'Try adjusting your search or filters'
                  : 'Add your first article to get started'}
              </p>
              {!searchQuery && branchFilter === 'all' && (
                <Button onClick={() => setShowForm(true)} className="mt-4">
                  <Plus className="h-4 w-4 mr-2" />
                  Add Article
                </Button>
              )}
            </div>
          )}
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between border-t border-gray-200 px-6 py-4">
            <div className="text-sm text-gray-700">
              Showing <span className="font-medium">{(currentPage - 1) * itemsPerPage + 1}</span> to{' '}
              <span className="font-medium">
                {Math.min(currentPage * itemsPerPage, filteredArticles.length)}
              </span>{' '}
              of <span className="font-medium">{filteredArticles.length}</span> articles
            </div>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                disabled={currentPage === 1}
              >
                Previous
              </Button>
              {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                // Show pages around current page
                let pageNum;
                if (totalPages <= 5) {
                  pageNum = i + 1;
                } else if (currentPage <= 3) {
                  pageNum = i + 1;
                } else if (currentPage >= totalPages - 2) {
                  pageNum = totalPages - 4 + i;
                } else {
                  pageNum = currentPage - 2 + i;
                }
                
                return (
                  <Button
                    key={pageNum}
                    variant={currentPage === pageNum ? 'default' : 'outline'}
                    size="sm"
                    onClick={() => setCurrentPage(pageNum)}
                  >
                    {pageNum}
                  </Button>
                );
              })}
              <Button
                variant="outline"
                size="sm"
                onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                disabled={currentPage === totalPages}
              >
                Next
              </Button>
            </div>
          </div>
        )}
      </div>

      {/* Delete Confirmation Dialog */}
      <Dialog open={!!articleToDelete} onOpenChange={() => {
        setArticleToDelete(null);
        setDeleteError(null);
      }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Article</DialogTitle>
          </DialogHeader>
          
          {deleteError ? (
            <div className="flex items-start gap-2 text-red-600">
              <AlertCircle className="h-5 w-5 shrink-0 mt-0.5" />
              <span>{deleteError}</span>
            </div>
          ) : (
            <div className="text-gray-600">
              Are you sure you want to delete this article? This action cannot be undone.
            </div>
          )}
          
          <div className="flex justify-end gap-4">
            <Button
              variant="outline"
              onClick={() => {
                setArticleToDelete(null);
                setDeleteError(null);
              }}
            >
              Cancel
            </Button>
            {!deleteError && (
              <Button 
                onClick={() => handleDeleteArticle()}
                className="bg-red-600 hover:bg-red-700"
              >
                Delete
              </Button>
            )}
          </div>
        </DialogContent>
      </Dialog>

      {/* Article Details Dialog */}
      <Dialog 
        open={!!showDetails} 
        onOpenChange={(open) => {
          if (!open) setShowDetails(null);
        }}
      >
        <DialogContent className="max-w-4xl overflow-hidden flex flex-col">
          <DialogHeader className="px-6 py-4 border-b">
            <DialogTitle>Article Details</DialogTitle>
          </DialogHeader>
          <div className="flex-1 overflow-y-auto p-6">
            {showDetails && (
              <ArticleDetails
                article={articles.find(a => a.id === showDetails)!}
                onClose={() => setShowDetails(null)}
                onEdit={() => {
                  setEditingArticle(articles.find(a => a.id === showDetails)!);
                  setShowDetails(null);
                  setShowForm(true);
                }}
              />
            )}
          </div>
        </DialogContent>
      </Dialog>

      {/* Import Dialog */}
      <Dialog open={showImport} onOpenChange={setShowImport}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Import Articles</DialogTitle>
          </DialogHeader>
          <ArticleImport
            onClose={() => setShowImport(false)}
            onSuccess={handleImportSuccess}
          />
        </DialogContent>
      </Dialog>

      {/* Export Dialog */}
      <Dialog open={showExport} onOpenChange={setShowExport}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Export Articles</DialogTitle>
          </DialogHeader>
          <ArticleExport
            articles={filteredArticles}
            onClose={() => setShowExport(false)}
            onSuccess={handleExportSuccess}
          />
        </DialogContent>
      </Dialog>

      {/* Bulk Rates Dialog */}
      <Dialog open={showBulkRates} onOpenChange={setShowBulkRates}>
        <DialogContent className="max-w-4xl">
          <DialogHeader>
            <DialogTitle>Bulk Rate Management</DialogTitle>
          </DialogHeader>
          <ArticleBulkRates
            onClose={() => setShowBulkRates(false)}
          />
        </DialogContent>
      </Dialog>
    </div>
  );
}