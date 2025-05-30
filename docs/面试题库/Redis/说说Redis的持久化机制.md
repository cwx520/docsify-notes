# 说说Redis的持久化机制

Redis有两种持久化机制：**RDB和AOF**。

+ RDB是一种快照持久化的方式，它会将Redis在某个时间点的数据状态以二进制的方式保存到硬盘上的一个文件中。RDB持久化可以通过配置定时或手动触发，也可以设置自动触发的条件。RDB的优点是生成的文件比AOF文件更小，恢复速度也更快，适合用于备份和灾难恢复。
+ AOF是一种追加日志持久化方式，它会将Redis执行的写命令追加到一个文件的末尾。当Redis重启时，它会重新执行这些写命令来恢复数据状态。AOF提供了更可靠的持久化方式，因为它可以保证每个写操作都被记录下来，并且不会发生数据丢失的情况。AOF文件可以根据配置进行同步写入硬盘的频率，包括每秒同步、每写入命令同步和禁用同步三种模式。

在使用持久化机制时，可以选择同时使用RDB和AOF，也可以只使用其中一种。同时使用两种方式时，Redis在重启时会先加载AOF文件来恢复数据，如果AOF文件不存在或损坏，则会尝试加载RDB文件。因此，AOF具有更高的优先级。



> 更新: 2023-09-20 15:45:02  
> 原文: <https://www.yuque.com/tulingzhouyu/db22bv/lefz0ffra2wp5veg>