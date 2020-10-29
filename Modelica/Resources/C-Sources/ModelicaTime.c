/* ModelicaTime.c - External functions for Modelica.Utilities.Time

   Copyright (C) 2020, Modelica Association and contributors
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

   3. Neither the name of the copyright holder nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
   OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// TODO: Remove when ModelicaTime.c will become part of ModelicaExternalC
#if defined(DYMOSIM)
#pragma once
#endif

#include "ModelicaTime.h"
#include "ModelicaUtilities.h"
#include "strptime.h"
#include "repl_str.h"

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#if !defined(NO_LOCALE)
#include <locale.h>
#endif

#if !defined(NO_TIME)
time_t epoch(int sec, int min, int hour, int mday, int mon, int year) {
    struct tm tres;
    time_t calendarTime;

    tres.tm_sec = sec;
    tres.tm_min = min;
    tres.tm_hour = hour;
    tres.tm_mday = mday;
    tres.tm_mon = mon - 1;
    tres.tm_year = year - 1900;
    tres.tm_isdst = -1;
    tres.tm_wday = 0;
    tres.tm_yday = 0;

    calendarTime = mktime(&tres);
    if (-1 == calendarTime) {
        ModelicaFormatError("Not possible to convert \"%4i-%02i-%02i %02i:%02i:%02i\" "
            "to time_t type in local time zone.\n", year, mon, mday, hour, min, sec);
    }
    return calendarTime;
}
#endif

double ModelicaTime_difftime(int ms, int sec, int min, int hour, int mday,
                             int mon, int year, int refYear) {
    /* Get elapsed seconds w.r.t. reference year */
#if defined(NO_TIME)
    return 0.0;
#else
    if (1 == mday && 1 == mon) {
        if (year == refYear) {
            return 60 * (60 * hour + min) + sec + ms/1000.0;
        }
        else if (1970 == year) {
            /* Avoid calling mktime for New Year 1970 in local time zone */
            const time_t endTime = epoch(sec, min, hour, 2, 1, 1970);
            const time_t startTime = epoch(0, 0, 0, 1, 1, refYear);
            return difftime(endTime, startTime) - 86400.0 + ms/1000.0;
        }
    }
    {
        const time_t endTime = epoch(sec, min, hour, mday, mon, year);
        if (1970 == refYear) {
            /* Avoid calling mktime for New Year 1970 in local time zone */
            const time_t startTime = epoch(0, 0, 0, 2, 1, 1970);
            return difftime(endTime, startTime) + 86400.0 + ms/1000.0;
        }
        else {
            const time_t startTime = epoch(0, 0, 0, 1, 1, refYear);
            return difftime(endTime, startTime) + ms/1000.0;
        }
    }
#endif
}

void ModelicaTime_localtime(_Out_ int* ms, _Out_ int* sec, _Out_ int* min,
                            _Out_ int* hour, _Out_ int* mday, _Out_ int* mon,
                            _Out_ int* year, double seconds, int refYear) {
    /* Convert elapsed seconds w.r.t. reference year */
#if defined(NO_TIME)
    *ms   = 0;
    *sec  = 0;
    *min  = 0;
    *hour = 0;
    *mday = 0;
    *mon  = 0;
    *year = 0;
#else
    struct tm tres;
    time_t calendarTime;
    double intPartOfSeconds;
    double fracPartOfSeconds;
#if !defined(_POSIX_) && !(defined(_MSC_VER) && _MSC_VER >= 1400)
    struct tm* tlocal;
#endif

    fracPartOfSeconds = modf(seconds, &intPartOfSeconds);
    calendarTime = (time_t)intPartOfSeconds;

    if (1970 == refYear) {
        /* Avoid calling mktime for New Year 1970 in local time zone */
        calendarTime = calendarTime + epoch(0, 0, 0, 2, 1, 1970) - (time_t)86400;
    }
    else {
        calendarTime = calendarTime + epoch(0, 0, 0, 1, 1, refYear);
    }

#if defined(_POSIX_)
    localtime_r(&calendarTime, &tres);          /* Time fields in local time zone */
#elif defined(_MSC_VER) && _MSC_VER >= 1400
    localtime_s(&tres, &calendarTime);          /* Time fields in local time zone */
#else
    tlocal = localtime(&calendarTime);          /* Time fields in local time zone */
    tres = *tlocal;
#endif

    /* Do not memcpy as you do not know which sizes are in the struct */
    *ms = (int)(fracPartOfSeconds*1000.0 + 0.5);
    *sec = tres.tm_sec;
    *min = tres.tm_min;
    *hour = tres.tm_hour;
    *mday = tres.tm_mday;
    *mon = 1 + tres.tm_mon;      /* Correct for month starting at 1 */
    *year = 1900 + tres.tm_year; /* Correct for 4-digit year */
#endif
}

_Ret_z_ const char* ModelicaTime_strftime(int ms, int sec, int min, int hour,
                                  int mday, int mon, int year,
                                  _In_z_ const char* format, int _maxSize) {
    /* Formatted time to string conversion */
#if defined(NO_TIME)
    return "";
#else
    struct tm tres;
    const size_t maxSize = (size_t)_maxSize;
    char* timePtr = ModelicaAllocateString(maxSize);
    time_t calendarTime = epoch(sec, min, hour, mday, mon, year);
#if !defined(_POSIX_) && !(defined(_MSC_VER) && _MSC_VER >= 1400)
    struct tm* tlocal;
#endif

#if defined(_POSIX_)
    localtime_r(&calendarTime, &tres);          /* Time fields in local time zone */
#elif defined(_MSC_VER) && _MSC_VER >= 1400
    localtime_s(&tres, &calendarTime);          /* Time fields in local time zone */
#else
    tlocal = localtime(&calendarTime);          /* Time fields in local time zone */
    tres = *tlocal;
#endif

    {
        char* format2;
        char* format3;
        char ms_str[32];
        size_t retLen;

        /* Special handling of milliseconds by non-standard %L format specifier */
        format2 = repl_str(format, "%%", "%|");
        sprintf(ms_str, "%03d", ms);
        format3 = repl_str(format2, "%L", ms_str);
        free(format2);
        format2 = repl_str(format3, "%|", "%%");
        free(format3);

#if !defined(NO_LOCALE) && (defined(_MSC_VER) && _MSC_VER >= 1400)
        {
            _locale_t loc = _create_locale(LC_TIME, "C");
            retLen = _strftime_l(timePtr, maxSize, format2, &tres, loc);
            _free_locale(loc);
        }
#elif !defined(NO_LOCALE) && (defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3))
        {
            locale_t loc = newlocale(LC_TIME, "C", NULL);
            retLen = strftime_l(timePtr, maxSize, format2, &tres, loc);
            freelocale(loc);
        }
#else
        retLen = strftime(timePtr, maxSize, format2, &tres);
#endif
        free(format2);
        if (retLen > 0 && retLen <= maxSize) {
            return (const char*)timePtr;
        }
        else {
            return "";
        }
    }
#endif
}

void ModelicaTime_strptime(_Out_ int* ms, _Out_ int* sec, _Out_ int* min,
                           _Out_ int* hour, _Out_ int* mday, _Out_ int* mon,
                           _Out_ int* year, _In_z_ const char* buf,
                           _In_z_ const char* format) {
    /* Formatted string to time conversion */
#if defined(NO_TIME)
    *ms   = 0;
    *sec  = 0;
    *min  = 0;
    *hour = 0;
    *mday = 0;
    *mon  = 0;
    *year = 0;
#else
    struct tm tres;
    int tmp = 0;

    memset(&tres, 0, sizeof(struct tm));
    if (NULL != strptime_ms(buf, format, &tres, &tmp)) {
        /* Do not memcpy as you do not know which sizes are in the struct */
        *ms = tmp;
        *sec = tres.tm_sec;
        *min = tres.tm_min;
        *hour = tres.tm_hour;
        *mday = tres.tm_mday;
        *mon = 1 + tres.tm_mon;      /* Correct for month starting at 1 */
        *year = 1900 + tres.tm_year; /* Correct for 4-digit year */
    }
    else {
        *ms   = 0;
        *sec  = 0;
        *min  = 0;
        *hour = 0;
        *mday = 0;
        *mon  = 0;
        *year = 0;
    }
#endif
}
