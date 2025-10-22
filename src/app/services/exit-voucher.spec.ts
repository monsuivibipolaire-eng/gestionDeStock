import { TestBed } from '@angular/core/testing';

import { ExitVoucher } from './exit-voucher';

describe('ExitVoucher', () => {
  let service: ExitVoucher;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(ExitVoucher);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
