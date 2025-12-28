import { User, Role, Grievance, GrievanceStatus, CreateGrievanceDTO } from '../types';

const API_BASE = 'http://127.0.0.1:5000';

export const api = {
  login: async (email: string, password: string): Promise<User> => {
    const res = await fetch(`${API_BASE}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    if (!res.ok) throw new Error('Invalid credentials');
    return res.json();
  },

  getGrievances: async (user: User): Promise<Grievance[]> => {
    const res = await fetch(`${API_BASE}/api/grievances?employee_id=${user.employee_id}&role=${user.role}`);
    if (!res.ok) throw new Error('Failed to fetch grievances');
    return res.json();
  },

  createGrievance: async (user: User, data: CreateGrievanceDTO): Promise<void> => {
    if (!data.acceptedTerms) throw new Error('You must agree to the terms.');
    
    const res = await fetch(`${API_BASE}/api/grievances`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        employee_id: user.employee_id,
        title: data.title,
        description: data.description
      })
    });
    if (!res.ok) throw new Error('Failed to create grievance');
  },

  updateStatus: async (grievanceId: number, status: GrievanceStatus): Promise<void> => {
    const res = await fetch(`${API_BASE}/api/grievances/${grievanceId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status })
    });
    if (!res.ok) throw new Error('Failed to update grievance');
  },

  deleteGrievance: async (grievanceId: number): Promise<void> => {
    throw new Error('Delete not yet implemented');
  }
};