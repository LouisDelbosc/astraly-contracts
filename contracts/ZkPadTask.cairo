# # SPDX-License-Identifier: AGPL-3.0-or-later

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bool import TRUE
from InterfaceAll import IZkPadIDOContract, Registration

# # @title Yagi Task
# # @description Triggers `calculate_allocation` at the end of the registration phase
# # @author ZkPad

#############################################
# #                 STORAGE                 ##
#############################################

@storage_var
func __lastExecuted() -> (lastExecuted : felt):
end

@storage_var
func __idoContractAddress() -> (address : felt):
end

#############################################
# #                 GETTERS                 ##
#############################################

@view
func lastExecuted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    lastExecuted : felt
):
    let (lastExecuted) = __lastExecuted.read()
    return (lastExecuted)
end

#############################################
# #                  TASK                   ##
#############################################

@view
func probeTask{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    taskReady : felt
):
    alloc_locals

    let (address : felt) = __idoContractAddress.read()
    assert_not_zero(address)

    let (registration : Registration) = IZkPadIDOContract.get_registration(contract_address=address)

    let (block_timestamp : felt) = get_block_timestamp()
    let (taskReady : felt) = is_le(registration.registration_time_ends, block_timestamp)

    return (taskReady=taskReady)
end

@external
func executeTask{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    alloc_locals
    let (taskReady : felt) = probeTask()
    with_attr error_message("ZkPadTask::Task not ready"):
        assert taskReady = TRUE
    end

    let (block_timestamp) = get_block_timestamp()
    __lastExecuted.write(block_timestamp)

    # Calculate Allocation
    let (ido_address : felt) = __idoContractAddress.read()
    IZkPadIDOContract.calculate_allocation(contract_address=ido_address)

    return ()
end

@external
func setIDOContractAddress{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> ():
    assert_not_zero(address)
    # TODO: Check if caller is IDO Factory (should be called during IDO Creation)
    __idoContractAddress.write(address)
    return ()
end