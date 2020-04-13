//
//  PageNotFoundVC.m
//  AccountManager
//
//  Created by  eadkenny on 2020/4/13.
//

#import "PageNotFoundVC.h"

@interface PageNotFoundVC ()

@end

@implementation PageNotFoundVC

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  UILabel *l = [[UILabel alloc] initWithFrame:self.view.bounds];
  l.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  l.text = @"啊哦~功能页面不见看！";
  l.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:l];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
  NSMethodSignature *sig = [super methodSignatureForSelector:aSelector];
  if(!sig)
  {
    return [self methodSignatureForSelector:@selector(noneRespond)];
  }
  return sig;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
  NSLog(@"forwardInvocation");
}

- (void)noneRespond {
  NSLog(@"noneRespond");
}

@end
