export enum Role {
  EMPLOYEE = 'Employee',
  ADMIN = 'HR Admin'
}

export enum GrievanceStatus {
  PENDING = 'Pending',
  IN_REVIEW = 'In Review',
  RESOLVED = 'Resolved'
}

export interface User {
  employee_id: number;
  name: string;
  email: string;
  role: Role;
}

export interface Grievance {
  grievance_id: number;
  employee_id: number;
  employee_name?: string; // For Admin display view join
  title: string;
  description: string;
  status: GrievanceStatus;
  created_at: string;
}

export interface CreateGrievanceDTO {
  title: string;
  description: string;
  acceptedTerms: boolean;
}