# Redis的热Key问题如何解决

Redis的热Key问题解决方案需要根据具体情况选择合适的方法。以下是一些常见的解决方案和对应的Java代码示例：  
解决方案

1. **本地缓存**  
使用本地缓存来缓解Redis的压力，从而减少对热Key的直接访问。

```java
import com.github.benmanes.caffeine.cache.Cache;  
import com.github.benmanes.caffeine.cache.Caffeine;  

import java.util.concurrent.TimeUnit;  

public class LocalCacheManager {  
    // 本地内存缓存实例  
    private Cache<String, String> localCache = Caffeine.newBuilder()  
    .expireAfterWrite(10, TimeUnit.MINUTES)  
    .maximumSize(1000)  
    .build();  

    public String getData(String key) {  
        return localCache.get(key, this::loadFromRedis);  
    }  

    private String loadFromRedis(String key) {  
        // 从Redis获取数据的模拟方法  
        return RedisClient.get(key);  
    }  
}
```



2. **请求分摊**

<font style="color:rgba(0, 0, 0, 0.82);">把热Key拆分成多个子Key，这样可以将读请求分摊到多个Key上，从而降低单Key的压力。</font>

```java
import java.util.List;  
import java.util.Random;  

public class KeyDistributor {  
    private static final int NUM_SHARDS = 10;  
    private List<String> shards;  

    public KeyDistributor(List<String> shardKeys) {  
        this.shards = shardKeys;  
    }  

    public String getDistributedKey(String originalKey) {  
        int shardNum = originalKey.hashCode() % NUM_SHARDS;  
        return shards.get(shardNum) + ":" + originalKey;  
    }  
} 
```



3. **限流**  
对热Key的访问进行限流，防止过多请求进入。

```java
import com.google.common.util.concurrent.RateLimiter;  

public class RateLimiterExample {  
    private RateLimiter rateLimiter = RateLimiter.create(10); // 每秒10个请求  

    public String accessResource(String key) {  
        if (rateLimiter.tryAcquire()) {  
            return RedisClient.get(key);  
        } else {  
            return "Rate limit exceeded";  
        }  
    }  
}
```



4. **监控和报警**  
通过设置监控来实时观测Redis的使用情况，及时应对热Key问题，例如通过Redis的INFO命令或使用监控工具。对于不可预知的热Key场景，我们一般来说都会接入我们的**热点探测系统**，定期上报我们对应key的调用次数，有热点探测系统检测是否是热key，然后通过sdk通知各个应用节点快速构建本地缓存，来抗住这些热key带来的流量。

# 短视频

我回答得挺好哈，为啥面试官**不满意**。。昨天一个工作了五年的粉丝朋友跟我说，面试被问到**Redis的热Key问题如何解决**，但是面试官对他的回答好像不太满意。

我们来分析下，我估计还有同学对Redis热Key问题是啥还不清楚的，先解释下，我们生产环境使用的都是redis集群来做缓存，热key主要是指某个特定的key，分布到了redis集群某个节点上，但是相比于其他同类型的key，这个key的访问频率极高，导致存储这个key的redis节点负载过高，甚至直接挂掉。

我们这个粉丝朋友是这么回答的，可以通过**缓存预热**，提前把热key数据加载到JVM的内存中，这样能减轻Redis的访问压力，其次我们还可以将热key数据**分片存储**到不同的Redis集群节点上，让整个集群所有节点一起来分担访问压力，这一看就是**烂大街的八股文**回答了。

这里面有几个问题，如果有的**缓存热key**是**不可预知**的，比如某些商品因为出现一个热点事件导致全网搜索以及访问量暴增，这种没法提前预热的怎么办？还有就是如果数据做了分片还是**扛不住巨大**的**访问压力**怎么办，这些关键问题都没讲，面试官当然不满意了。

第一个问题对于不可预知的热key，一般在互联网公司都会开发一个**热点探测系统**，比如**京东**的**jdhotkey**，当系统出现访问热点时，热点探测系统能马上感知到，并及时通知各个web应用构建自己的本地缓存来抗住大并发。第二个问题一般我们都会做一些**限流熔断**的处理，比如在nginx层，网关层，包括一些核心接口我们都会加上一些限流的处理以防过大压力导致系统崩溃的问题。

当然，可能面试官会继续问你**热点探测系统**内部是**如何实现**的，关于这个问题想听的同学可以点赞关注，后面马上安排！

> 更新: 2024-08-07 20:17:25  
> 原文: <https://www.yuque.com/tulingzhouyu/db22bv/qf8k72bdh2er2mdl>