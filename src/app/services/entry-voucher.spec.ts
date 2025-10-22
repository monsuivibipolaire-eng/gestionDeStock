import { TestBed } from '@angular/core/testing';

import { EntryVoucher } from './entry-voucher';

describe('EntryVoucher', () => {
  let service: EntryVoucher;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(EntryVoucher);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
