export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

type Table<Row, Insert, Update = Partial<Insert>> = {
  Row: Row;
  Insert: Insert;
  Update: Update;
  Relationships: [];
};

type AuditEventRow = {
  action: string;
  actor_database_role: string;
  actor_user_id: string | null;
  branch_id: number | null;
  details: Json;
  id: number;
  occurred_at: string;
  organization_id: number | null;
  target_id: string | null;
  target_type: string;
};
type BranchMembershipRow = {
  branch_id: number;
  created_at: string;
  created_by: string;
  id: number;
  organization_id: number;
  organization_membership_id: number;
  status: string;
  updated_at: string;
};
type BranchRow = {
  code: string;
  created_at: string;
  created_by: string;
  id: number;
  name: string;
  organization_id: number;
  status: string;
  timezone: string;
  updated_at: string;
};
type ClassEnrollmentRow = {
  branch_id: number;
  class_id: number;
  created_at: string;
  created_by: string;
  enrolled_at: string;
  id: number;
  organization_id: number;
  organization_membership_id: number;
  status: string;
  updated_at: string;
};
type ClassObjectiveRow = {
  branch_id: number;
  class_id: number;
  created_at: string;
  created_by: string;
  id: number;
  objective_id: number;
  organization_id: number;
  subject_id: number;
  syllabus_id: number;
  syllabus_version_id: number;
};
type ClassTeacherRow = {
  branch_id: number;
  class_id: number;
  created_at: string;
  created_by: string;
  id: number;
  organization_id: number;
  organization_membership_id: number;
  status: string;
  updated_at: string;
};
type ClassRow = {
  academic_year: string;
  branch_id: number;
  code: string;
  created_at: string;
  created_by: string;
  id: number;
  name: string;
  organization_id: number;
  status: string;
  subject_id: number;
  updated_at: string;
};
type OrganizationMembershipRow = {
  created_at: string;
  created_by: string;
  id: number;
  joined_at: string | null;
  organization_id: number;
  status: string;
  updated_at: string;
  user_id: string;
};
type OrganizationRow = {
  created_at: string;
  created_by: string;
  id: number;
  name: string;
  region_code: string;
  slug: string;
  status: string;
  updated_at: string;
};
type ProfileRow = {
  created_at: string;
  display_name: string;
  id: string;
  status: string;
  updated_at: string;
};
type RoleAssignmentRow = {
  assigned_at: string;
  assigned_by: string;
  branch_id: number | null;
  id: number;
  organization_id: number;
  organization_membership_id: number;
  role: string;
  status: string;
  updated_at: string;
};
type SubjectRow = {
  code: string;
  created_at: string;
  created_by: string;
  id: number;
  name: string;
  organization_id: number;
  status: string;
  syllabus_id: number;
  syllabus_version_id: number;
  updated_at: string;
};
type SyllabusObjectiveRow = {
  code: string;
  created_at: string;
  created_by: string;
  description: string | null;
  id: number;
  organization_id: number | null;
  parent_objective_id: number | null;
  sequence_number: number;
  syllabus_id: number;
  syllabus_version_id: number;
  title: string;
  updated_at: string;
};
type SyllabusVersionRow = {
  created_at: string;
  created_by: string;
  id: number;
  organization_id: number | null;
  published_at: string | null;
  status: string;
  syllabus_id: number;
  updated_at: string;
  version_label: string;
};
type SyllabusRow = {
  code: string;
  created_at: string;
  created_by: string;
  description: string | null;
  id: number;
  organization_id: number | null;
  scope: string;
  status: string;
  title: string;
  updated_at: string;
};
type TimetableEntryRow = {
  branch_id: number;
  class_id: number;
  created_at: string;
  created_by: string;
  effective_from: string;
  effective_to: string | null;
  ends_at: string;
  id: number;
  organization_id: number;
  room: string | null;
  starts_at: string;
  status: string;
  updated_at: string;
  weekday: number;
};

export type Database = {
  __InternalSupabase: { PostgrestVersion: "14.15" };
  public: {
    Tables: {
      audit_events: Table<
        AuditEventRow,
        Omit<AuditEventRow, "id" | "occurred_at"> & { id?: never; occurred_at?: string }
      >;
      branch_memberships: Table<
        BranchMembershipRow,
        Omit<BranchMembershipRow, "id" | "created_at" | "updated_at" | "status"> & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          status?: string;
        }
      >;
      branches: Table<
        BranchRow,
        Omit<BranchRow, "id" | "created_at" | "updated_at" | "status" | "timezone"> & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          status?: string;
          timezone?: string;
        }
      >;
      class_enrollments: Table<
        ClassEnrollmentRow,
        Omit<ClassEnrollmentRow, "id" | "created_at" | "updated_at" | "enrolled_at" | "status"> & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          enrolled_at?: string;
          status?: string;
        }
      >;
      class_objectives: Table<
        ClassObjectiveRow,
        Omit<ClassObjectiveRow, "id" | "created_at"> & { id?: never; created_at?: string }
      >;
      class_teachers: Table<
        ClassTeacherRow,
        Omit<ClassTeacherRow, "id" | "created_at" | "updated_at" | "status"> & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          status?: string;
        }
      >;
      classes: Table<
        ClassRow,
        Omit<ClassRow, "id" | "created_at" | "updated_at" | "status"> & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          status?: string;
        }
      >;
      organization_memberships: Table<
        OrganizationMembershipRow,
        Omit<
          OrganizationMembershipRow,
          "id" | "created_at" | "updated_at" | "joined_at" | "status"
        > & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          joined_at?: string | null;
          status?: string;
        }
      >;
      organizations: Table<
        OrganizationRow,
        Omit<OrganizationRow, "id" | "created_at" | "updated_at" | "status" | "region_code"> & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          status?: string;
          region_code?: string;
        }
      >;
      profiles: Table<
        ProfileRow,
        Omit<ProfileRow, "created_at" | "updated_at" | "status"> & {
          created_at?: string;
          updated_at?: string;
          status?: string;
        }
      >;
      role_assignments: Table<
        RoleAssignmentRow,
        Omit<RoleAssignmentRow, "id" | "assigned_at" | "updated_at" | "status"> & {
          id?: never;
          assigned_at?: string;
          updated_at?: string;
          status?: string;
        }
      >;
      subjects: Table<
        SubjectRow,
        Omit<SubjectRow, "id" | "created_at" | "updated_at" | "status"> & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          status?: string;
        }
      >;
      syllabus_objectives: Table<
        SyllabusObjectiveRow,
        Omit<
          SyllabusObjectiveRow,
          | "id"
          | "organization_id"
          | "created_at"
          | "updated_at"
          | "parent_objective_id"
          | "description"
          | "sequence_number"
        > & {
          id?: never;
          organization_id?: number | null;
          created_at?: string;
          updated_at?: string;
          parent_objective_id?: number | null;
          description?: string | null;
          sequence_number?: number;
        }
      >;
      syllabus_versions: Table<
        SyllabusVersionRow,
        Omit<
          SyllabusVersionRow,
          "id" | "organization_id" | "created_at" | "updated_at" | "published_at" | "status"
        > & {
          id?: never;
          organization_id?: number | null;
          created_at?: string;
          updated_at?: string;
          published_at?: string | null;
          status?: string;
        }
      >;
      syllabuses: Table<
        SyllabusRow,
        Omit<SyllabusRow, "id" | "created_at" | "updated_at" | "description" | "status"> & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          description?: string | null;
          status?: string;
        }
      >;
      timetable_entries: Table<
        TimetableEntryRow,
        Omit<
          TimetableEntryRow,
          "id" | "created_at" | "updated_at" | "effective_to" | "room" | "status"
        > & {
          id?: never;
          created_at?: string;
          updated_at?: string;
          effective_to?: string | null;
          room?: string | null;
          status?: string;
        }
      >;
    };
    Views: { [_ in never]: never };
    Functions: {
      create_class_bundle: {
        Args: {
          academic_year_input: string;
          branch_id_input: number;
          class_code_input: string;
          class_name_input: string;
          effective_from_input: string;
          effective_to_input?: string;
          ends_at_input: string;
          objective_id_input: number;
          organization_id_input: number;
          room_input: string;
          starts_at_input: string;
          subject_id_input: number;
          weekday_input: number;
        };
        Returns: { class_id: number; timetable_entry_id: number }[];
      };
      create_custom_syllabus_bundle: {
        Args: {
          objective_code_input: string;
          objective_description_input: string;
          objective_title_input: string;
          organization_id_input: number;
          syllabus_code_input: string;
          syllabus_description_input: string;
          syllabus_title_input: string;
          version_label_input: string;
        };
        Returns: { objective_id: number; syllabus_id: number; syllabus_version_id: number }[];
      };
    };
    Enums: { [_ in never]: never };
    CompositeTypes: { [_ in never]: never };
  };
};

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">;
type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;
export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema["Tables"] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends { Insert: infer I }
      ? I
      : never
    : never;
export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema["Tables"] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends { Update: infer U }
      ? U
      : never
    : never;
export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    keyof DefaultSchema["Enums"] | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never;
export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    keyof DefaultSchema["CompositeTypes"] | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = { public: { Enums: {} } } as const;
