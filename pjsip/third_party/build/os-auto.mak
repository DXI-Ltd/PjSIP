
ifneq (,1)
ifeq (0,1)
# External
else
DIRS += gsm
endif
endif

ifneq (,1)
DIRS += ilbc
endif

ifneq (,1)
ifeq (0,1)
# External speex
else
DIRS += speex
endif
endif

ifneq (,1)
DIRS += g7221
endif

ifneq ($(findstring pa,),)
ifeq (0,1)
# External PA
else
DIRS += portaudio
endif
endif

ifeq (0,1)
# External SRTP
else
DIRS += srtp
endif

ifeq (libresample,libresample)
DIRS += resample
endif
