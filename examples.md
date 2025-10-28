# Example Mermaid Diagrams

This file contains example mermaid diagrams for testing the vim-mermaid-ascii plugin.

## Simple Flow

```mermaid
graph LR
A --> B
B --> C
C --> D
```

## More Complex Flow

```mermaid
graph TD
A --> B
A --> C
B --> C
B -->|example| D
D --> C
```

## Labeled Edges

```mermaid
graph LR
Start -->|input| Process
Process -->|success| End
Process -->|error| Error
Error --> Start
```

## Network Topology

```mermaid
graph TD
Internet --> Router
Router --> Switch1
Router --> Switch2
Switch1 --> PC1
Switch1 --> PC2
Switch2 --> Server1
Switch2 --> Server2
```

Try running `:MermaidAsciiRender` to see these diagrams rendered as ASCII art!
