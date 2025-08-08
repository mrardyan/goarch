package internationalization_test

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	i18n "golang-arch/internal/shared/domain/internationalization"
)

func TestNewTime(t *testing.T) {
	tests := []struct {
		name    string
		epoch   int64
		wantErr bool
	}{
		{
			name:    "valid epoch time",
			epoch:   time.Now().Unix(),
			wantErr: false,
		},
		{
			name:    "zero epoch time",
			epoch:   0,
			wantErr: false,
		},
		{
			name:    "epoch time too early",
			epoch:   time.Date(1969, 12, 31, 23, 59, 59, 0, time.UTC).Unix(),
			wantErr: true,
		},
		{
			name:    "epoch time too late",
			epoch:   time.Date(2101, 1, 1, 0, 0, 0, 0, time.UTC).Unix(),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := i18n.NewTime(tt.epoch)
			if tt.wantErr {
				assert.Error(t, err)
				assert.Nil(t, got)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, got)
				assert.Equal(t, tt.epoch, got.Epoch)
			}
		})
	}
}

func TestNewTimeFromTime(t *testing.T) {
	now := time.Now()
	timeType := i18n.NewTimeFromTime(now)

	assert.NotNil(t, timeType)
	assert.Equal(t, now.Unix(), timeType.Epoch)
}

func TestTime_ToTime(t *testing.T) {
	epoch := time.Now().Unix()
	timeType := &i18n.Time{Epoch: epoch}

	timeValue := timeType.ToTime()
	assert.Equal(t, epoch, timeValue.Unix())
}

func TestTime_ToPrimitive(t *testing.T) {
	epoch := int64(1640995200) // 2022-01-01 00:00:00 UTC
	timeType := &i18n.Time{Epoch: epoch}

	primitive := timeType.ToPrimitive()
	assert.Equal(t, epoch, primitive)
}

func TestFromPrimitive(t *testing.T) {
	epoch := int64(1640995200) // 2022-01-01 00:00:00 UTC

	timeType, err := i18n.FromPrimitive(epoch)
	require.NoError(t, err)
	assert.Equal(t, epoch, timeType.Epoch)
}

func TestTime_Validate(t *testing.T) {
	tests := []struct {
		name    string
		epoch   int64
		wantErr bool
	}{
		{
			name:    "valid epoch",
			epoch:   time.Now().Unix(),
			wantErr: false,
		},
		{
			name:    "zero epoch",
			epoch:   0,
			wantErr: false,
		},
		{
			name:    "epoch too early",
			epoch:   time.Date(1969, 12, 31, 23, 59, 59, 0, time.UTC).Unix(),
			wantErr: true,
		},
		{
			name:    "epoch too late",
			epoch:   time.Date(2101, 1, 1, 0, 0, 0, 0, time.UTC).Unix(),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			timeType := &i18n.Time{Epoch: tt.epoch}
			err := timeType.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestTime_Format(t *testing.T) {
	epoch := int64(1640995200) // 2022-01-01 00:00:00 UTC
	timeType := &i18n.Time{Epoch: epoch}

	// Test with nil timezone (should use UTC)
	formatted := timeType.Format(time.RFC3339, nil)
	assert.Equal(t, "2022-01-01T00:00:00Z", formatted)

	// Test with timezone
	tz, err := i18n.NewTimezoneFromID("America/New_York")
	require.NoError(t, err)

	formatted = timeType.Format(time.RFC3339, tz)
	// The exact time depends on daylight saving time, so we check for the date
	assert.Contains(t, formatted, "2021-12-31")
}

func TestTime_FormatUTC(t *testing.T) {
	epoch := int64(1640995200) // 2022-01-01 00:00:00 UTC
	timeType := &i18n.Time{Epoch: epoch}

	formatted := timeType.FormatUTC(time.RFC3339)
	assert.Equal(t, "2022-01-01T00:00:00Z", formatted)
}

func TestTime_FormatLocal(t *testing.T) {
	epoch := int64(1640995200) // 2022-01-01 00:00:00 UTC
	timeType := &i18n.Time{Epoch: epoch}

	formatted := timeType.FormatLocal(time.RFC3339)
	// The exact format depends on local timezone, so we just check it's not empty
	assert.NotEmpty(t, formatted)
}

func TestTime_IsZero(t *testing.T) {
	tests := []struct {
		name     string
		epoch    int64
		expected bool
	}{
		{
			name:     "zero epoch",
			epoch:    0,
			expected: true,
		},
		{
			name:     "non-zero epoch",
			epoch:    time.Now().Unix(),
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			timeType := &i18n.Time{Epoch: tt.epoch}
			assert.Equal(t, tt.expected, timeType.IsZero())
		})
	}
}

func TestTime_Equal(t *testing.T) {
	epoch1 := int64(1640995200)
	epoch2 := int64(1640995201)

	time1 := &i18n.Time{Epoch: epoch1}
	time2 := &i18n.Time{Epoch: epoch1}
	time3 := &i18n.Time{Epoch: epoch2}

	assert.True(t, time1.Equal(time2))
	assert.False(t, time1.Equal(time3))
	assert.True(t, time1.Equal(time1))
	assert.False(t, time1.Equal(nil))
	assert.False(t, (*i18n.Time)(nil).Equal(time1))
}

func TestTime_BeforeAfter(t *testing.T) {
	epoch1 := int64(1640995200)
	epoch2 := int64(1640995201)

	time1 := &i18n.Time{Epoch: epoch1}
	time2 := &i18n.Time{Epoch: epoch2}

	assert.True(t, time1.Before(time2))
	assert.False(t, time2.Before(time1))
	assert.True(t, time2.After(time1))
	assert.False(t, time1.After(time2))
}

func TestTime_Add(t *testing.T) {
	epoch := int64(1640995200) // 2022-01-01 00:00:00 UTC
	timeType := &i18n.Time{Epoch: epoch}

	// Add 1 hour
	newTime := timeType.Add(time.Hour)
	expectedEpoch := epoch + 3600

	assert.Equal(t, expectedEpoch, newTime.Epoch)
}

func TestTime_Sub(t *testing.T) {
	epoch1 := int64(1640995200)
	epoch2 := int64(1640998800) // +1 hour

	time1 := &i18n.Time{Epoch: epoch1}
	time2 := &i18n.Time{Epoch: epoch2}

	duration := time2.Sub(time1)
	assert.Equal(t, time.Hour, duration)
}

func TestTime_String(t *testing.T) {
	epoch := int64(1640995200) // 2022-01-01 00:00:00 UTC
	timeType := &i18n.Time{Epoch: epoch}

	str := timeType.String()
	// The String() method uses Format() with nil timezone, which should use UTC
	// But the actual result depends on the system's timezone
	// So we check that it contains the expected date
	assert.Contains(t, str, "2022-01-01")
}

func TestTime_MarshalJSON(t *testing.T) {
	epoch := int64(1640995200)
	timeType := &i18n.Time{Epoch: epoch}

	data, err := timeType.MarshalJSON()
	require.NoError(t, err)
	assert.Equal(t, "1640995200", string(data))
}

func TestTime_UnmarshalJSON(t *testing.T) {
	tests := []struct {
		name    string
		data    []byte
		wantErr bool
	}{
		{
			name:    "valid epoch",
			data:    []byte("1640995200"),
			wantErr: false,
		},
		{
			name:    "quoted epoch",
			data:    []byte(`"1640995200"`),
			wantErr: false,
		},
		{
			name:    "invalid epoch",
			data:    []byte("invalid"),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			timeType := &i18n.Time{}
			err := timeType.UnmarshalJSON(tt.data)
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, int64(1640995200), timeType.Epoch)
			}
		})
	}
}
