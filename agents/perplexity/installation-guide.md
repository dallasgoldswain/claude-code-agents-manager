# Ruby Subagent Installation Guide

## Quick Setup

### 1. Create Directory Structure
Create the following directories in your project root:

```bash
mkdir -p .claude/agents
```

### 2. Install the Ruby Expert Agent
Save the `ruby-expert-agent.md` file to:
```
.claude/agents/ruby-expert.md
```

### 3. Project Configuration (Optional)
Save the `claude-project-config.md` file as:
```
.claude/CLAUDE.md
```

## Usage Examples

### Automatic Activation
The Ruby Expert agent will automatically engage when Claude detects:
- Ruby files (.rb, .rake, Gemfile, etc.)
- Rails-specific patterns
- Ruby-related queries in your messages

### Manual Activation
Use these phrases to explicitly invoke the Ruby Expert:

```
> Use the ruby-expert agent to refactor this method
> Apply Ruby metaprogramming patterns to simplify this code
> Optimize this Rails controller for better performance
> Review this gem structure for best practices
> Add minitest coverage for this class
```

### Parallel Processing
For complex tasks, use multiple agents:

```
> Use 3 ruby-expert agents to:
  1. Analyze performance bottlenecks
  2. Review test coverage gaps  
  3. Suggest refactoring opportunities
```

## Advanced Configuration

### Custom Triggers
The agent activates automatically when it detects:

- Database queries without proper loading strategies
- Methods longer than 10 lines
- Classes with more than 5 public methods
- Missing test coverage
- Performance bottlenecks (N+1 queries, etc.)
- Poor metaprogramming practices
- Dependency management issues

### Integration with Development Workflow

#### Pre-commit Hook
The agent can review code changes before commits:
```
> Review these changes with ruby-expert before I commit
```

#### Code Review Process
Use for pull request reviews:
```
> Use ruby-expert to analyze this PR for Ruby best practices
```

#### Performance Monitoring
Regular performance audits:
```
> Run ruby-expert analysis on the entire codebase for optimization opportunities
```

## Troubleshooting

### Agent Not Activating
- Ensure the file is saved as `.claude/agents/ruby-expert.md`
- Check that the YAML frontmatter is properly formatted
- Verify the `agent-type` field is set to `ruby-expert`

### Custom Tools Not Working
- Confirm `allowed-tools` includes the tools you need
- Available tools: "Read", "Write", "Bash", "Grep", "Glob", "Execute"

### Performance Issues
- The agent uses Claude Sonnet 3.5 model for optimal Ruby expertise
- For faster responses, you can change `model:` to `claude-haiku-3-5`

## File Structure
Your final project structure should look like:

```
your-project/
├── .claude/
│   ├── agents/
│   │   └── ruby-expert.md
│   └── CLAUDE.md (optional project config)
├── app/
├── config/
├── Gemfile
└── ...
```

## Tips for Maximum Effectiveness

1. **Be Specific**: Instead of "fix this code", say "optimize this ActiveRecord query for better performance"

2. **Context Matters**: Provide relevant context about your app's requirements and constraints

3. **Iterative Improvement**: Use the agent for ongoing code reviews and refactoring sessions

4. **Testing Focus**: Always ask for test coverage alongside code improvements

5. **Performance Awareness**: Mention performance requirements upfront for better optimization suggestions

## Getting the Most Value

The Ruby Expert agent is designed to be proactive and educational. It will:

- Explain why certain patterns are preferred
- Provide multiple solution approaches when appropriate
- Include performance considerations in recommendations
- Suggest comprehensive test coverage
- Point out potential security issues
- Recommend modern Ruby and Rails practices

Start using it today to elevate your Ruby code quality and learn advanced patterns from an expert perspective!