import React, { useState, useEffect } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { Truck, ArrowRight, Loader2 } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import SignInForm from '@/components/auth/SignInForm';
import SignUpForm from '@/components/auth/SignUpForm';
import ForgotPasswordForm from '@/components/auth/ForgotPasswordForm';
import EmailVerification from '@/components/auth/EmailVerification';
import LoadingScreen from '@/components/auth/LoadingScreen';
import { supabase } from '@/lib/supabase';
import { getOrganizationClientCode } from '@/lib/organizations';

export default function SignInPage() {
  const { user, loading } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [view, setView] = React.useState<'client' | 'signIn' | 'signUp' | 'forgotPassword' | 'verifyEmail'>('client');
  const [email, setEmail] = React.useState('');
  const [error, setError] = React.useState<string | null>(null);
  const [clientCode, setClientCode] = useState('');
  const [clientError, setClientError] = useState<string | null>(null);
  const [loadingOrg, setLoadingOrg] = useState(true);
  const [selectedOrg, setSelectedOrg] = useState<{
    id: string;
    name: string;
    display_name: string;
    client_code: string;
  } | null>(null);

  // Load K2K organization on mount
  useEffect(() => {
    async function loadK2K() {
      try {
        const org = await getOrganizationClientCode('k2k-logistics');
        if (org) {
          setSelectedOrg({
            id: '', // We don't need the ID for display
            name: 'k2k-logistics',
            display_name: org.display_name,
            client_code: org.client_code
          });
        }
      } catch (err) {
        console.error('Failed to load K2K organization:', err);
      } finally {
        setLoadingOrg(false);
      }
    }
    loadK2K();
  }, []);

  // Get redirect path from location state
  const from = location.state?.from?.pathname || '/dashboard';

  if (loading) {
    return <LoadingScreen />;
  }

  if (user) {
    return <Navigate to={from} replace />;
  }

  const handleClientCodeSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setClientError(null);

    if (!clientCode) {
      setClientError('Please enter a client code');
      return;
    }

    try {
      const { data, error } = await supabase.rpc('get_organization_by_code', {
        code: clientCode.toUpperCase()
      });

      if (error) throw error;
      if (!data || data.length === 0) {
        setClientError('Invalid client code');
        return;
      }

      setSelectedOrg(data[0]);
      setView('signIn');
    } catch (err) {
      console.error('Failed to verify client code:', err);
      setClientError('Failed to verify client code');
    }
  };

  const handleSuccess = () => {
    // Will automatically redirect when auth state updates
    navigate(from, { replace: true });
  };

  const handleError = (error: string) => {
    setError(error);
  };

  const handleEmailVerification = (email: string) => {
    setEmail(email);
    setView('verifyEmail');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50">
      <div className="flex min-h-screen">
        {/* Left side - Branding */}
        <div className="hidden lg:flex lg:flex-1 p-12 bg-gradient-to-br from-blue-600 to-indigo-700">
          <div className="max-w-2xl mx-auto flex flex-col justify-between">
            <div>
              <div className="flex items-center gap-3">
                <div className="h-12 w-12 bg-white/10 rounded-xl flex items-center justify-center backdrop-blur-sm">
                  <Truck className="h-6 w-6 text-white" />
                </div>
                <h1 className="text-2xl font-bold text-white">FastTrack Logistics</h1>
              </div>
              <p className="mt-8 text-3xl font-bold text-white">
                Streamline Your Logistics Operations with Our Comprehensive Management System
              </p>
              <p className="mt-4 text-lg text-blue-100">
                Manage your entire logistics operation from a single platform. Track shipments,
                manage inventory, and optimize your delivery routes with ease.
              </p>
            </div>

            <div className="space-y-6">
              <div className="flex items-center gap-4">
                <div className="h-12 w-12 bg-white/10 rounded-xl flex items-center justify-center">
                  <span className="text-2xl font-bold text-white">5K+</span>
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-white">Active Users</h3>
                  <p className="text-blue-100">Trust FastTrack for their logistics needs</p>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <div className="h-12 w-12 bg-white/10 rounded-xl flex items-center justify-center">
                  <span className="text-2xl font-bold text-white">1M+</span>
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-white">Deliveries</h3>
                  <p className="text-blue-100">Successfully completed each month</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Right side - Auth forms */}
        <div className="flex-1 flex items-center justify-center p-8">
          <div className="w-full max-w-md">
            {error && (
              <div className="mb-6 bg-red-50 border border-red-200 text-red-600 p-4 rounded-xl text-sm">
                {error}
              </div>
            )}

            <div className="bg-white rounded-2xl shadow-xl p-8">
              {view === 'client' && (
                <form onSubmit={handleClientCodeSubmit} className="space-y-6">
                  <div className="text-center">
                    <h2 className="text-2xl font-bold text-gray-900">Welcome Back</h2>
                    <p className="text-gray-600 mt-2">Enter your client code to continue</p>
                  </div>

                  {loadingOrg ? (
                    <div className="flex items-center justify-center py-4">
                      <Loader2 className="h-6 w-6 animate-spin text-blue-600" />
                    </div>
                  ) : selectedOrg ? (
                    <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 text-center">
                      <p className="font-medium text-blue-900">{selectedOrg.display_name}</p>
                      <p className="text-blue-700 text-2xl font-mono mt-2">{selectedOrg.client_code}</p>
                      <Button 
                        onClick={() => setView('signIn')} 
                        className="mt-4 w-full"
                      >
                        Continue to Login
                        <ArrowRight className="h-4 w-4 ml-2" />
                      </Button>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      <div>
                        <Input
                          value={clientCode}
                          onChange={(e) => setClientCode(e.target.value.toUpperCase())}
                          placeholder="Enter client code"
                          className="text-center text-2xl tracking-widest uppercase"
                          maxLength={6}
                        />
                        {clientError && (
                          <p className="text-sm text-red-500 mt-1">{clientError}</p>
                        )}
                      </div>

                      <Button type="submit" className="w-full">
                        Continue
                        <ArrowRight className="h-4 w-4 ml-2" />
                      </Button>
                    </div>
                  )}
                </form>
              )}

              {view === 'signIn' && (
                <SignInForm
                  onSuccess={handleSuccess}
                  onError={handleError}
                  onForgotPassword={() => setView('forgotPassword')}
                  onToggleMode={() => setView('signUp')}
                  selectedOrg={selectedOrg}
                />
              )}

              {view === 'signUp' && (
                <SignUpForm
                  onSuccess={handleEmailVerification}
                  onError={handleError}
                  onToggleMode={() => setView('signIn')}
                  selectedOrg={selectedOrg}
                />
              )}

              {view === 'forgotPassword' && (
                <ForgotPasswordForm
                  onSuccess={() => setView('signIn')}
                  onBack={() => setView('signIn')}
                />
              )}

              {view === 'verifyEmail' && (
                <EmailVerification
                  email={email}
                  onClose={() => setView('signIn')}
                />
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}