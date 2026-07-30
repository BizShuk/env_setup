package system

import "strings"

func valuesAfterLabel(output, label string) []string {
	var values []string
	for line := range strings.SplitSeq(output, "\n") {
		line = strings.TrimSpace(line)
		if !strings.HasPrefix(line, label) {
			continue
		}
		value := strings.TrimSpace(strings.TrimPrefix(line, label))
		if value != "" {
			values = append(values, value)
		}
	}
	return values
}

func namesBeforeMarker(output, marker string) []string {
	var names []string
	var previous string
	for line := range strings.SplitSeq(output, "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		if strings.Contains(line, marker) {
			name := strings.TrimSuffix(previous, ":")
			if name != "" {
				names = append(names, name)
			}
			continue
		}
		previous = line
	}
	return names
}

func firstNonEmpty(values []string) string {
	for _, value := range values {
		if value = strings.TrimSpace(value); value != "" {
			return value
		}
	}
	return ""
}
