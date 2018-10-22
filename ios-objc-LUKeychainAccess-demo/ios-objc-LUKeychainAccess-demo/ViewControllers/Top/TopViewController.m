//
//  TopViewController.m
//  ios-objc-LUKeychainAccess-demo
//
//  Created by YukiOkudera on 2018/10/23.
//  Copyright © 2018 YukiOkudera. All rights reserved.
//

#import <LUKeychainAccess/LUKeychainAccess.h>
#import <mach/mach.h>
#import "TopViewController.h"

@interface TopViewController () <LUKeychainErrorHandler>

@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (nonatomic) LUKeychainAccess *keychainAccess;

@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UILabel *freeLabel;
@property (weak, nonatomic) IBOutlet UILabel *activeLabel;
@property (weak, nonatomic) IBOutlet UILabel *inActiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *percentLabel;

@end

@implementation TopViewController
{
    void *_pointerArray[1024];
}

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.keychainAccess = [LUKeychainAccess standardKeychainAccess];
    self.keychainAccess.errorHandler = self;

    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                                      target:self
                                                    selector:@selector(timerInfo:)
                                                    userInfo:nil
                                                     repeats:YES];
    [timer fire];
}

#pragma mark - IBAction

- (IBAction)didTapLoadKeyButton:(UIButton *)sender {

    // フリーのメモリサイズを確認
    unsigned long freeNum = [self getFreeMemory] / 1024 / 1024;

    // 5Mbyteを残してHeapを圧迫
    unsigned long roopNum = freeNum - 5;
    for (int i = 0; i < roopNum; i++) {
        _pointerArray[i] = AllocateDirtyBlock(1024 * 1024);
    }

    NSString *key = [[LUKeychainAccess standardKeychainAccess] stringForKey:@"SAMPLE_KEY"];

    if (key) {
        NSLog(@"key: %@", key);
    } else {
        NSLog(@"key is nil.");
    }
    self.outputLabel.text = key;
}

#pragma mark - Selector

- (void)timerInfo:(NSTimer*)timer {

    int totalNum = (float)[[NSProcessInfo processInfo] physicalMemory] / 1024 / 1024;
    unsigned long freeNum = [self getFreeMemory] / 1024 / 1024;
    unsigned long activeNum = [self getActiveMemory] / 1024 / 1024;
    unsigned long inactiveNum = [self getInActiveMemory] / 1024 / 1024;
    float percentNum = (float)freeNum / (float)totalNum;

    self.totalLabel.text = [NSString stringWithFormat:@"TotalMemory: %d[MByte]", totalNum];
    self.freeLabel.text = [NSString stringWithFormat:@"FreeMemory: %lu[MByte]", freeNum];
    self.activeLabel.text = [NSString stringWithFormat:@"ActiveMemory: %lu[MByte]", activeNum];
    self.inActiveLabel.text = [NSString stringWithFormat:@"InActiveMemory: %lu[MByte]", inactiveNum];
    self.percentLabel.text = [NSString stringWithFormat:@"Percent: %02f", percentNum];
}

#pragma mark - Others

- (unsigned long)getFreeMemory {

    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
        return 0;
    }

    unsigned long mem_free = (unsigned long)vm_stat.free_count* pagesize;

    return mem_free;
}

- (unsigned long)getActiveMemory {

    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
        return 0;
    }

    unsigned long mem_active = (unsigned long)vm_stat.active_count* pagesize;

    return mem_active;
}

- (unsigned long)getInActiveMemory {

    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
        return 0;
    }

    unsigned long mem_inactive = (unsigned long)vm_stat.inactive_count* pagesize;

    return mem_inactive;
}

#pragma mark - DirtyBlock

static void *AllocateDirtyBlock(NSUInteger size) {
    Byte* block = malloc(size);
    for (NSUInteger offset = 0; offset < size; offset++) {
        block[offset] = offset & 0xff;
    }
    return block;
}

#pragma mark - LUKeychainErrorHandler

- (void)keychainAccess:(LUKeychainAccess *)keychainAccess receivedError:(NSError *)error {

    NSLog(@"receivedError: %ld_%@", (long)error.code, error.description);


    UIAlertController *alert = [UIAlertController alertControllerWithTitle:error.localizedRecoverySuggestion
                                                                   message:error.localizedFailureReason ?: error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
