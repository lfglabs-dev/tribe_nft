use array::ArrayTrait;
use traits::Into;
use integer::{u256_safe_divmod, u256_as_non_zero, u256_from_felt252};

fn append_number_ascii(num: u256, ref arr: Array<felt252>) {
    let (q, r, _) = u256_safe_divmod(num, u256_as_non_zero(u256_from_felt252(10)));
    let digit = r.low + 48; // ascii

    if q == (u256 { low: 0, high: 0 }) {
        arr.append(digit.into());
        return ();
    }

    let added_len = append_number_ascii(q, ref arr);
    arr.append(digit.into());
}
