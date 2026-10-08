/**
 * StoreBuddy Cloud Website - Type Definitions
 */

export type PlatformType = 'windows' | 'android' | 'mac' | 'linux';

export interface Release {
  id: string;
  version: string;
  platform: PlatformType;
  channel: 'stable' | 'beta' | 'alpha';
  download_url: string;
  release_notes: string;
  release_date: string;
  published: boolean;
  file_size?: string;
  sha256?: string;
  created_at?: string;
}

export interface UserGuideStep {
  stepNumber: number;
  title: string;
  subtitle: string;
  icon: string;
  badge: string;
  description: string;
  bullets: string[];
  codeSnippet?: string;
  actionText?: string;
  actionUrl?: string;
}

export interface FeatureItem {
  id: string;
  icon: string;
  title: string;
  tag: string;
  summary: string;
  highlights: string[];
}

export interface FaqItem {
  question: string;
  answer: string;
  category: string;
}
