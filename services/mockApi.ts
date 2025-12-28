import { User, Role, Grievance, GrievanceStatus, CreateGrievanceDTO } from '../types';

// Initial Mock Data
const MOCK_USERS: User[] = [
  { employee_id: 1, name: 'John Doe', email: 'employee@test.com', role: Role.EMPLOYEE },
  { employee_id: 2, name: 'Jane Smith', email: 'jane@test.com', role: Role.EMPLOYEE },
  { employee_id: 99, name: 'Admin User', email: 'admin@test.com', role: Role.ADMIN },
];

// Initialize storage if empty
const initStorage = () => {
  if (!localStorage.getItem('hr_grievances')) {
    const initialGrievances: Grievance[] = [
      {
        grievance_id: 101,
        employee_id: 1,
        title: 'Office Temperature',
        description: 'The AC is too cold in the north wing.',
        status: GrievanceStatus.PENDING,
        created_at: new Date(Date.now() - 86400000).toISOString()
      },
      {
        grievance_id: 102,
        employee_id: 2,
        title: 'Safety Hazard',
        description: 'Loose cables in the hallway.',
        status: GrievanceStatus.RESOLVED,
        created_at: new Date(Date.now() - 172800000).toISOString()
      }
    ];
    localStorage.setItem('hr_grievances', JSON.stringify(initialGrievances));
  }
};

initStorage();

export const mockApi = {
  login: async (email: string, password: string): Promise<User> => {
    // Simulating network delay
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Simple mock auth - in real python app this would check password_hash
    const user = MOCK_USERS.find(u => u.email === email);
    
    // For demo purposes, any password works if email exists
    if (user && password.length > 0) {
      return user;
    }
    throw new Error('Invalid credentials');
  },

  getGrievances: async (user: User): Promise<Grievance[]> => {
    await new Promise(resolve => setTimeout(resolve, 300));
    const allGrievances: Grievance[] = JSON.parse(localStorage.getItem('hr_grievances') || '[]');

    if (user.role === Role.ADMIN) {
      // Admin sees all, join with user names
      return allGrievances.map(g => ({
        ...g,
        employee_name: MOCK_USERS.find(u => u.employee_id === g.employee_id)?.name || 'Unknown'
      }));
    } else {
      // Employee sees only their own
      return allGrievances.filter(g => g.employee_id === user.employee_id);
    }
  },

  createGrievance: async (user: User, data: CreateGrievanceDTO): Promise<void> => {
    await new Promise(resolve => setTimeout(resolve, 500));
    
    if (!data.acceptedTerms) {
      throw new Error('You must agree to the terms.');
    }

    const allGrievances: Grievance[] = JSON.parse(localStorage.getItem('hr_grievances') || '[]');
    const newId = allGrievances.length > 0 ? Math.max(...allGrievances.map(g => g.grievance_id)) + 1 : 1;

    const newGrievance: Grievance = {
      grievance_id: newId,
      employee_id: user.employee_id,
      title: data.title,
      description: data.description,
      status: GrievanceStatus.PENDING,
      created_at: new Date().toISOString()
    };

    localStorage.setItem('hr_grievances', JSON.stringify([...allGrievances, newGrievance]));
  },

  updateStatus: async (grievanceId: number, status: GrievanceStatus): Promise<void> => {
    await new Promise(resolve => setTimeout(resolve, 300));
    const allGrievances: Grievance[] = JSON.parse(localStorage.getItem('hr_grievances') || '[]');
    
    const updated = allGrievances.map(g => 
      g.grievance_id === grievanceId ? { ...g, status } : g
    );
    
    localStorage.setItem('hr_grievances', JSON.stringify(updated));
  },

  deleteGrievance: async (grievanceId: number): Promise<void> => {
    await new Promise(resolve => setTimeout(resolve, 300));
    const allGrievances: Grievance[] = JSON.parse(localStorage.getItem('hr_grievances') || '[]');
    
    const filtered = allGrievances.filter(g => g.grievance_id !== grievanceId);
    
    localStorage.setItem('hr_grievances', JSON.stringify(filtered));
  }
};