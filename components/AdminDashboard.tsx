import React, { useState, useEffect } from 'react';
import { User, Grievance, GrievanceStatus } from '../types';
import { mockApi } from '../services/mockApi';
import { Loader2, Trash2, Save, Filter } from 'lucide-react';

interface AdminDashboardProps {
  user: User;
}

const AdminDashboard: React.FC<AdminDashboardProps> = ({ user }) => {
  const [grievances, setGrievances] = useState<Grievance[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [editingId, setEditingId] = useState<number | null>(null);
  
  // Filter state
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  const fetchGrievances = async () => {
    setIsLoading(true);
    try {
      const data = await mockApi.getGrievances(user);
      setGrievances(data);
    } catch (err) {
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchGrievances();
  }, [user]);

  const handleStatusChange = async (id: number, newStatus: GrievanceStatus) => {
    setEditingId(id);
    try {
      await mockApi.updateStatus(id, newStatus);
      // Optimistic update
      setGrievances(prev => prev.map(g => g.grievance_id === id ? { ...g, status: newStatus } : g));
    } catch (err) {
      console.error('Failed to update status');
    } finally {
      setEditingId(null);
    }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('Are you sure you want to delete this grievance? This action cannot be undone.')) {
      return;
    }
    
    setEditingId(id);
    try {
      await mockApi.deleteGrievance(id);
      setGrievances(prev => prev.filter(g => g.grievance_id !== id));
    } catch (err) {
      console.error('Failed to delete grievance');
    } finally {
      setEditingId(null);
    }
  };

  const filteredGrievances = statusFilter === 'ALL' 
    ? grievances 
    : grievances.filter(g => g.status === statusFilter);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-800">Admin Dashboard</h2>
          <p className="text-sm text-gray-500 mt-1">Manage and review employee grievances</p>
        </div>
        
        <div className="flex items-center space-x-2 bg-white border border-gray-300 rounded-md px-3 py-1.5">
            <Filter size={16} className="text-gray-400" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="text-sm border-none focus:ring-0 text-gray-700 bg-transparent outline-none"
            >
              <option value="ALL">All Statuses</option>
              {Object.values(GrievanceStatus).map(s => (
                <option key={s} value={s}>{s}</option>
              ))}
            </select>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden border border-gray-200">
        {isLoading ? (
          <div className="p-12 flex justify-center">
            <Loader2 className="animate-spin text-blue-500 h-8 w-8" />
          </div>
        ) : filteredGrievances.length === 0 ? (
          <div className="p-12 text-center text-gray-500">
            <p>No grievances found.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Employee</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-1/3">Issue</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredGrievances.map((g) => (
                  <tr key={g.grievance_id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">#{g.grievance_id}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{g.employee_name}</div>
                      <div className="text-xs text-gray-500">{new Date(g.created_at).toLocaleDateString()}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">{g.title}</div>
                      <div className="text-sm text-gray-500 truncate max-w-xs">{g.description}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <select
                        value={g.status}
                        onChange={(e) => handleStatusChange(g.grievance_id, e.target.value as GrievanceStatus)}
                        disabled={editingId === g.grievance_id}
                        className={`text-xs font-semibold rounded-full px-2 py-1 border-0 ring-1 ring-inset focus:ring-2 focus:ring-blue-600 ${
                          g.status === GrievanceStatus.RESOLVED ? 'bg-green-50 text-green-700 ring-green-600/20' :
                          g.status === GrievanceStatus.IN_REVIEW ? 'bg-yellow-50 text-yellow-800 ring-yellow-600/20' :
                          'bg-gray-50 text-gray-600 ring-gray-500/10'
                        }`}
                      >
                        {Object.values(GrievanceStatus).map(s => (
                          <option key={s} value={s}>{s}</option>
                        ))}
                      </select>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button
                        onClick={() => handleDelete(g.grievance_id)}
                        disabled={editingId === g.grievance_id}
                        className="text-red-600 hover:text-red-900 disabled:opacity-50"
                        title="Delete Grievance"
                      >
                         {editingId === g.grievance_id ? <Loader2 className="animate-spin h-5 w-5" /> : <Trash2 size={18} />}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default AdminDashboard;