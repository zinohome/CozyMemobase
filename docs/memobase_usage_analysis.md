# Memobase 使用方式深入分析

## 1. 概述

Memobase 是一个**基于用户画像的记忆系统**，专为 LLM 应用提供长期用户记忆能力。它通过用户画像（Profile）和事件时间线（Event Timeline）来管理和检索用户记忆。

### 核心特点

- **用户画像驱动**：不是为 Agent 设计，而是为真实用户设计
- **性能优化**：在 LOCOMO 基准测试中达到顶级搜索性能
- **成本控制**：内置缓冲区批量处理，减少 LLM 调用次数（从 3-10 次减少到固定 3 次，成本降低 40-50%）
- **低延迟**：在线延迟控制在 100ms 以内
- **时间感知**：支持时间相关的记忆查询

## 2. 核心概念

### 2.1 用户（User）

每个用户都有一个唯一的 `user_id`，Memobase 会为每个用户维护：
- **用户画像（Profile）**：结构化的用户属性，如姓名、年龄、兴趣等
- **事件时间线（Event Timeline）**：用户交互历史记录

### 2.2 数据块（Blob）

所有用户数据都以 Blob 形式存储，支持多种类型：
- `ChatBlob`：对话消息
- `DocBlob`：文档内容
- `SummaryBlob`：摘要
- `CodeBlob`：代码片段
- `ImageBlob`：图片
- `TranscriptBlob`：转录文本

### 2.3 缓冲区（Buffer）

Memobase 使用缓冲区机制来批量处理数据：
- 数据先进入缓冲区
- 当缓冲区达到阈值（如 1024 tokens）或空闲时间超过阈值（如 1 小时）时自动刷新
- 也可以手动调用 `flush()` 来触发处理

### 2.4 用户画像（Profile）

用户画像采用三级结构：
- **Topic（主题）**：如 `basic_info`、`interest`、`work` 等
- **Sub-topic（子主题）**：如 `name`、`age`、`location` 等
- **Content（内容）**：具体的值

示例：
```python
{
  "basic_info": {
    "name": "Gus",
    "age": 25
  },
  "interest": {
    "foods": "Mexican cuisine"
  }
}
```

### 2.5 事件（Event）

事件记录用户交互中的重要时刻，包含：
- **Profile Delta**：此次事件更新的用户画像
- **Event Tip**：事件摘要
- **Event Tags**：事件标签，用于分类和搜索

## 3. 基本使用流程

### 3.1 初始化客户端

```python
from memobase import MemoBaseClient

# 同步客户端
client = MemoBaseClient(
    project_url="http://localhost:8019",  # 本地或云端地址
    api_key="secret"  # 或从环境变量 MEMOBASE_API_KEY 读取
)

# 异步客户端
from memobase import AsyncMemoBaseClient
async_client = AsyncMemoBaseClient(
    project_url="http://localhost:8019",
    api_key="secret"
)
```

### 3.2 用户管理

```python
# 创建用户
uid = client.add_user({"name": "Gus"})

# 获取用户
user = client.get_user(uid)

# 获取或创建用户（如果不存在则创建）
user = client.get_or_create_user(uid)

# 更新用户信息
client.update_user(uid, {"age": 25})

# 删除用户
client.delete_user(uid)
```

### 3.3 插入数据

```python
from memobase import ChatBlob

# 创建对话数据块
messages = [
    {"role": "user", "content": "Hello, I'm Gus"},
    {"role": "assistant", "content": "Hi, nice to meet you, Gus!"}
]

blob = ChatBlob(messages=messages)

# 插入数据（异步，默认不等待处理）
blob_id = user.insert(blob)

# 同步插入（等待处理完成）
blob_id = user.insert(blob, sync=True)
```

### 3.4 刷新缓冲区

```python
# 异步刷新（默认）
user.flush()

# 同步刷新（等待处理完成）
user.flush(sync=True)
```

### 3.5 获取用户画像

```python
# 获取所有画像
profiles = user.profile()

# 获取 JSON 格式的画像
profile_json = user.profile(need_json=True)

# 限制返回的 token 数量
profiles = user.profile(max_token_size=500)

# 优先返回特定主题
profiles = user.profile(prefer_topics=["basic_info", "interest"])

# 只返回特定主题
profiles = user.profile(only_topics=["basic_info"])

# 限制每个主题的子主题数量
profiles = user.profile(max_subtopic_size=3)

# 为不同主题设置不同的限制
profiles = user.profile(topic_limits={"basic_info": 5, "interest": 10})
```

### 3.6 获取上下文（Context）

Context API 是 Memobase 的核心功能，它将用户画像和事件打包成一个可以直接插入到 LLM prompt 中的字符串：

```python
# 基本用法
context = user.context()

# 限制 token 数量
context = user.context(max_token_size=500)

# 优先特定主题
context = user.context(prefer_topics=["basic_info"])

# 基于最近对话进行语义搜索（提高相关性）
recent_chats = [
    {"role": "user", "content": "What is my name?"}
]
context = user.context(chats=recent_chats)

# 自定义 prompt 模板
custom_prompt = """
# Memory
{profile_section}

## Latest Events:
{event_section}
"""
context = user.context(customize_context_prompt=custom_prompt)

# 控制画像和事件的比例
context = user.context(profile_event_ratio=0.6)  # 60% 画像，40% 事件

# 设置事件相似度阈值
context = user.context(event_similarity_threshold=0.2)

# 限制事件时间范围（最近 N 天）
context = user.context(time_range_in_days=180)
```

### 3.7 事件管理

```python
# 获取最近的事件
events = user.event(topk=10)

# 搜索相关事件
events = user.search_event(
    query="work related",
    topk=10,
    similarity_threshold=0.2,
    time_range_in_days=180
)

# 通过标签搜索事件
events = user.search_event_by_tags(
    tags=["emotion", "romance"],  # 必须同时有这两个标签
    tag_values={"emotion": "happy", "topic": "work"},  # 标签值精确匹配
    topk=10
)

# 搜索事件摘要（更细粒度）
gists = user.search_event_gist(
    query="work related",
    topk=10
)

# 更新事件
user.update_event(event_id, {"event_tip": "Updated tip"})

# 删除事件
user.delete_event(event_id)
```

### 3.8 手动管理画像

```python
# 添加画像
profile_id = user.add_profile(
    content="Software Engineer",
    topic="work",
    sub_topic="title"
)

# 更新画像
user.update_profile(
    profile_id=profile_id,
    content="Senior Software Engineer",
    topic="work",
    sub_topic="title"
)

# 删除画像
user.delete_profile(profile_id)
```

## 4. 高级使用场景

### 4.1 与 OpenAI 集成

Memobase 提供了 OpenAI SDK 的补丁，可以无缝集成：

```python
from memobase import MemoBaseClient
from openai import OpenAI
from memobase.patch.openai import openai_memory

# 初始化 OpenAI 客户端
openai_client = OpenAI()

# 初始化 Memobase 客户端
mb_client = MemoBaseClient(
    project_url="http://localhost:8019",
    api_key="secret"
)

# 应用补丁
openai_client = openai_memory(
    openai_client,
    mb_client,
    additional_memory_prompt="Make sure the user's query needs the memory.",
    max_context_size=1000
)

# 使用 OpenAI 客户端（自动集成记忆）
response = openai_client.chat.completions.create(
    messages=[{"role": "user", "content": "What's my name?"}],
    model="gpt-4o-mini",
    user_id="user_123"  # 关键：传入 user_id 来触发记忆
)

# 会话结束时刷新记忆
openai_client.flush("user_123")

# 获取记忆 prompt
memory_prompt = openai_client.get_memory_prompt("user_123")
```

### 4.2 异步使用

```python
from memobase import AsyncMemoBaseClient, ChatBlob

async def main():
    async with AsyncMemoBaseClient(
        project_url="http://localhost:8019",
        api_key="secret"
    ) as client:
        # 创建用户
        uid = await client.add_user()
        user = await client.get_user(uid)
        
        # 插入数据
        blob = ChatBlob(messages=[
            {"role": "user", "content": "Hello"}
        ])
        await user.insert(blob)
        
        # 刷新
        await user.flush(sync=True)
        
        # 获取上下文
        context = await user.context()
        print(context)
```

### 4.3 用户分析和跟踪

```python
# 获取用户画像进行分析
profiles = user.profile()

# 筛选特定条件的用户
def under_age_30(profile):
    return profile.topic == "basic_info" and \
           profile.sub_topic == "age" and \
           int(profile.content) < 30

def love_cat(profile):
    return profile.topic == "interest" and \
           profile.sub_topic == "pets" and \
           "cat" in profile.content.lower()

is_under_30 = any(under_age_30(p) for p in profiles)
loves_cats = any(love_cat(p) for p in profiles)
```

### 4.4 个性化推荐

```python
def pick_an_ad(profiles):
    work_titles = [
        p for p in profiles 
        if p.topic == "work" and p.sub_topic == "title"
    ]
    
    if not work_titles:
        return None
    
    title = work_titles[0].content
    if title == "Software Engineer":
        return "Deep Learning Course"
    elif title == "Data Scientist":
        return "MLOps Tools"
    # ...
    
    return None
```

## 5. 配置和自定义

### 5.1 项目配置

```python
# 获取当前配置
config = client.get_config()

# 更新配置
client.update_config(new_config_yaml)
```

### 5.2 使用统计

```python
# 获取使用情况
usage = client.get_usage()

# 获取每日使用情况
daily_usage = client.get_daily_usage(days=7)
```

### 5.3 用户列表

```python
# 获取所有用户
users = client.get_all_users(
    search="",  # 搜索关键词
    order_by="updated_at",  # 排序字段
    order_desc=True,  # 降序
    limit=10,  # 每页数量
    offset=0  # 偏移量
)
```

## 6. 最佳实践

### 6.1 数据插入时机

- **实时插入**：每次对话后立即插入，使用异步模式（`sync=False`）
- **批量刷新**：在会话结束时调用 `flush(sync=True)` 确保记忆被处理

### 6.2 Context 使用

- **默认场景**：使用 `user.context()` 获取基本上下文
- **对话相关**：传入 `chats` 参数进行语义搜索，提高相关性
- **成本控制**：使用 `max_token_size` 限制上下文大小
- **主题过滤**：使用 `prefer_topics` 或 `only_topics` 控制返回内容

### 6.3 性能优化

- **异步操作**：对于非关键路径，使用异步插入和刷新
- **批量处理**：利用缓冲区机制，避免频繁刷新
- **缓存策略**：Context 结果可以缓存，因为用户画像不会频繁变化

### 6.4 错误处理

```python
from memobase.error import ServerError

try:
    user = client.get_user(user_id)
except ServerError as e:
    # 用户不存在，创建新用户
    user = client.get_or_create_user(user_id)
```

## 7. 工作流程总结

典型的 Memobase 使用流程：

1. **初始化**：创建 MemoBaseClient
2. **用户管理**：获取或创建用户
3. **数据收集**：插入对话、文档等数据（异步）
4. **处理记忆**：调用 `flush()` 触发记忆提取
5. **获取上下文**：使用 `context()` 获取记忆 prompt
6. **集成 LLM**：将 context 插入到 LLM 的 system prompt 中
7. **持续更新**：随着用户交互，不断插入新数据并刷新

## 8. 关键 API 总结

### MemoBaseClient
- `ping()` - 检查连接
- `add_user()` - 创建用户
- `get_user()` - 获取用户
- `get_or_create_user()` - 获取或创建用户
- `update_user()` - 更新用户
- `delete_user()` - 删除用户
- `get_config()` - 获取配置
- `update_config()` - 更新配置
- `get_usage()` - 获取使用统计

### User
- `insert()` - 插入数据块
- `flush()` - 刷新缓冲区
- `profile()` - 获取用户画像
- `context()` - 获取上下文 prompt
- `event()` - 获取事件
- `search_event()` - 搜索事件
- `search_event_by_tags()` - 按标签搜索事件
- `add_profile()` - 手动添加画像
- `update_profile()` - 更新画像
- `delete_profile()` - 删除画像

## 9. 注意事项

1. **数据持久化**：默认情况下，Blob 在处理后会被删除，只保留记忆。如需保留原始数据，需要配置存储选项。

2. **成本控制**：
   - 使用 `chats` 参数会增加延迟（0.1-1秒）和成本（100-200 tokens/chat）
   - 使用 `full_profile_and_only_search_event=False` 会显著增加延迟（2-5秒）和成本（100-1000 tokens/chat）

3. **时间范围**：事件搜索默认只返回最近 180 天的事件，可通过 `time_range_in_days` 调整。

4. **同步 vs 异步**：
   - 同步操作会等待处理完成，适合需要立即获取结果的场景
   - 异步操作立即返回，适合批量处理场景

5. **用户 ID**：Memobase 会将字符串转换为 UUID，确保同一用户使用相同的 user_id。

## 10. 参考资料

- 官方文档：https://docs.memobase.io/
- GitHub：https://github.com/memodb-io/memobase
- Playground：https://app.memobase.io/playground
- Discord：https://discord.gg/YdgwU4d9NB

