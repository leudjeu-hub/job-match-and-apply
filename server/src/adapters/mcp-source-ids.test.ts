import { describe, expect, it } from 'vitest';
import { mcpSearchableSourceIds } from './mcp-job-source.js';

describe('mcpSearchableSourceIds', () => {
  it('maps the legacy Bundesagentur id, drops the LinkedIn profile and removes duplicates', () => {
    expect(mcpSearchableSourceIds(['stepstone', 'bundesagentur-arbeit', 'linkedin-profile', 'arbeitsagentur']))
      .toEqual(['stepstone', 'arbeitsagentur']);
  });
});
