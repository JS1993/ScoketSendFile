//
//  ViewController.m
//  Demo4_JS_ScoketSendFile
//
//  Created by  江苏 on 16/3/26.
//  Copyright © 2016年 jiangsu. All rights reserved.
//

#import "ViewController.h"
#import "AsyncSocket.h"
@interface ViewController ()<AsyncSocketDelegate>
@property(nonatomic,strong)AsyncSocket* serverSocket;
@property(nonatomic,strong)AsyncSocket* clientScoket;
@property(nonatomic,strong)AsyncSocket* myServer;
@property(nonatomic,strong)NSMutableData* allData;
@property(nonatomic,copy)NSString* host;
@property(nonatomic)int fileLength;
@property(nonatomic,copy)NSString* fileName;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.allData=[NSMutableData data];
    self.serverSocket=[[AsyncSocket alloc]initWithDelegate:self];
    [self.serverSocket acceptOnPort:8000 error:nil];
}
- (IBAction)send:(id)sender {
    self.clientScoket=[[AsyncSocket alloc]initWithDelegate:self];
    [self.clientScoket connectToHost:@"192.168.1.105" onPort:8000 error:nil];
    //发文件
    NSString* filePath=@"/Volumes/外置磁盘/视频/lua.mp4";
    NSData* fileData=[NSData dataWithContentsOfFile:filePath];
    NSString* headerString=[NSString stringWithFormat:@"%@&&%lu",[filePath lastPathComponent],(unsigned long)fileData.length];
    NSData* headerData=[headerString dataUsingEncoding:NSUTF8StringEncoding];
    //创建一个100字节的可变data
    NSMutableData* sendAllData=[NSMutableData dataWithLength:100];
    //把头替换到100里面
    [sendAllData replaceBytesInRange:NSMakeRange(0, headerData.length) withBytes:headerData.bytes];
    [sendAllData appendData:fileData];
    [self.clientScoket writeData:sendAllData withTimeout:-1 tag:0];
}
-(void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket{
    self.myServer=newSocket;
}
-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    self.host=host;
    [self.myServer readDataWithTimeout:-1 tag:0];
}

-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
   //1.把前100个字节取出
    NSData* headerData=[data subdataWithRange:NSMakeRange(0, 100)];
    NSString* headerString=[[NSString alloc]initWithData:headerData encoding:NSUTF8StringEncoding];
    //2.判断是否是第一部分数据，如果是，则需要提前传输文件信息
    if (headerString&&[headerString componentsSeparatedByString:@"&&"].count==2) {
        NSArray* headers=[headerString componentsSeparatedByString:@"&&"];
        self.fileName=headers[0];
        self.fileLength=[headers[1] intValue];
        //把头文件抛掉，剩下的文件取出
        NSData* subFileData=[data subdataWithRange:NSMakeRange(100, data.length-100)];
        [self.allData appendData:subFileData];
    }else{
        [self.allData appendData:data];
    }
    //判断文件是否接收完成
    if(self.allData.length==self.fileLength){
        NSString* newFilePath=[@"/Users/jiangsu/Desktop" stringByAppendingPathComponent:self.fileName];
        [self.allData writeToFile:newFilePath atomically:YES];
    }
    [self.myServer readDataWithTimeout:-1 tag:0];
}
-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}
-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
