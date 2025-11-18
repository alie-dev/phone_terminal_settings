/**
 * ESLint configuration for Tailwind CSS multiline formatting
 * - eslint-plugin-better-tailwindcss: 의미단위 그룹화 + 자동 줄바꿈 + Tailwind 순서 정렬
 */
import betterTailwindcss from 'eslint-plugin-better-tailwindcss';
import sveltePlugin from 'eslint-plugin-svelte';
import svelteParser from 'svelte-eslint-parser';

// Tailwind 공통 룰 설정
const tailwindRules = {
  // Tailwind 클래스 순서 정렬
  'better-tailwindcss/enforce-consistent-class-order': 'warn',

  // 의미단위 그룹화 + 자동 줄바꿈
  'better-tailwindcss/enforce-consistent-line-wrapping': ['warn', {
    printWidth: 80,           // 최대 줄 길이
    classesPerLine: 0,        // 0 = printWidth로만 제한
    group: 'newLine',         // 의미별 그룹을 새 줄로 분리 (emptyLine/newLine/never)
    indent: 2,                // 들여쓰기 스페이스 개수
    lineBreakStyle: 'unix',   // 줄바꿈 스타일
  }],

  // 중복 클래스 제거
  'better-tailwindcss/no-duplicate-classes': 'warn',

  // 불필요한 공백 제거
  'better-tailwindcss/no-unnecessary-whitespace': 'warn',
};

export default [
  // JSX/TSX/JS/TS 파일 설정
  {
    files: ['**/*.jsx', '**/*.tsx', '**/*.ts', '**/*.js'],

    // JSX 파싱을 위한 언어 옵션
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      parserOptions: {
        ecmaFeatures: {
          jsx: true,  // JSX 지원 활성화
        },
      },
    },

    plugins: {
      'better-tailwindcss': betterTailwindcss,
    },

    rules: tailwindRules,

    // Tailwind 설정은 제거 (기본 Tailwind 클래스만 인식)
    // 실제 프로젝트에서 사용할 때는 아래 settings 추가 필요
    /*
    settings: {
      'better-tailwindcss': {
        // Tailwind CSS 4.x (CSS 파일 방식)
        entryPoint: 'src/app.css',
      },
    },
    */
  },

  // Svelte 파일 설정
  {
    files: ['**/*.svelte'],

    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      parser: svelteParser,  // Svelte 전용 파서 사용
    },

    plugins: {
      svelte: sveltePlugin,
      'better-tailwindcss': betterTailwindcss,
    },

    rules: {
      ...tailwindRules,
      // Svelte 기본 룰 비활성화 (Tailwind 포맷팅과 충돌 방지)
      'svelte/no-unused-svelte-ignore': 'off',
    },
  },
];
