include ../make.inc

MODULES = nulib.F90 \
	  nulibtable.F90 \
	  linterp_many_mod.F90


SOURCES = fermi.F90 \
	  helpers.F90 \
	  gauss_laguerre_helpers.F90 \
	  gauss_legendre_helpers.F90 \
	  electron_positron_annihilation.F90 \
	  absorption_crosssections.F90 \
	  emissivities.F90 \
	  scattering.F90 \
	  weak_magnetism_correction.F90 \
	  inelastic_electron_scattering.F90 \
	  eos_interface.F90 \
	  input_parser.F90 \
	  nulibtable_reader.F90

EXE_SOURCES = nulibtable_driver.F90 \
	      point_example.F90

ifeq ($(WEAK_RATES),1)
EXE_SOURCES += make_table_weakrates.F90
else
EXE_SOURCES += make_table_example.F90
endif

ifeq ($(NUCLEI_HEMPEL),1)
	MODULES += nuclei_distribution_helpers.F90
	F_SOURCES = extra_code_and_tables/sfho_frdm_comp/sfho_frdm_composition_module.f
	INCLUDES += -I./extra_code_and_tables/sfho_frdm_comp
	DEFS += -DNUCLEI_HEMPEL 
endif


#the weak_rates module requires M. Hempel's
#EOS dependent NSE distributions
ifeq ($(WEAK_RATES),1)
ifeq ($(NUCLEI_HEMPEL),0)
$(error NUCLEI_HEMPEL must be 1 for weakrates)
endif

	MODULES += weakrates/ratetable.F90 \
		   weakrates/rateapprox.F90 \
		   weakrates/ratelibrary.F90 \
		   weakrates/interface.F90 \

	DEFS += -DWEAK_RATES 

endif


#dual openmp+mpi jobs may work, but are not currently supported
ifeq ($(OPENMP),1)
ifeq ($(MPI),1)
$(error MPI and OPENMP cannot be used simultaneously)
endif
endif

# openmp compiler flags
ifeq ($(OPENMP),1)
ifeq ($(F90),gfortran)
	F90FLAGS += -fopenmp
else
	F90FLAGS += -openmp
endif	
endif

# degub compiler flag
ifeq ($(DEBUG),1)
	F90FLAGS += -DDEBUG
endif

# MPI compiler and flags
ifeq ($(MPI),1)
	F90 = mpif90
	DEFS += -D__MPI__
endif

#take care of EOS dependences etc
INCLUDES = -I./nuc_eos $(HDF5INCS)
EXTRADEPS = nuc_eos/nuc_eos.a requested_interactions.inc constants.inc ../make.inc
ifeq ($(HELMHOLTZ_EOS),1)
	DEFS += -DHELMHOLTZ_EOS
	f90_SOURCES = other_eos/helmholtz/helmholtz.f90
else
	DEFS += -DHAVE_NUC_EOS
	f90_SOURCES =
endif

# convert source filenames to compiled filenames
f90_OBJECTS=$(f90_SOURCES:.f90=.o )
F_OBJECTS=$(F_SOURCES:.f=.o )
MOD_OBJECTS=$(MODULES:.F90=.o )
OBJECTS=$(SOURCES:.F90=.o )
EXECUTABLES=$(EXE_SOURCES:.F90=)

all: $(EXECUTABLES)

$(EXECUTABLES): nulib.a 
	$(F90) $(F90FLAGS) $(DEFS) $(INCLUDES) -o $@ $@.F90 $< $(HDF5LIBS)
	mv $@ ..

nulib.a: $(EXTRADEPS) $(F_OBJECTS) $(MOD_OBJECTS) $(OBJECTS) $(f90_OBJECTS)
	ar -r nulib.a $(F_OBJECTS) $(MOD_OBJECTS) $(OBJECTS) $(f90_OBJECTS) nuc_eos/*.o

$(MOD_OBJECTS): %.o: %.F90  $(EXTRADEPS)
	$(F90) $(F90FLAGS) $(DEFS) $(INCLUDES) -c $< -o $@

$(OBJECTS): %.o: %.F90 $(EXTRADEPS) $(MOD_OBJECTS)
	$(F90) $(F90FLAGS) $(DEFS) $(INCLUDES) -c $< -o $@ 

$(F_OBJECTS): %.o: %.f  $(EXTRADEPS)
	$(F90) $(F90FLAGS) $(DEFS) $(INCLUDES) -c $< -o $@	

$(f90_OBJECTS): %.o: %.f90  $(EXTRADEPS)
	$(F90) $(F90FLAGS) $(DEFS) $(INCLUDES) -c $< -o $@	

nuc_eos/nuc_eos.a: nuc_eos/*.F90 nuc_eos/*.f
	$(MAKE) -C nuc_eos

clean:
	rm -rf ../make_table_example
	rm -rf ../make_table_weakrates
	rm -rf ../point_example
	rm -rf ../nulibtable_driver
	rm -rf *.o
	rm -rf *~
	rm -rf *.mod
	rm -rf *.a
	$(MAKE) -C nuc_eos clean	
	rm -rf ./extra_code_and_tables/sfho_frdm_comp/sfho_frdm_composition_module.o
	rm -rf ./other_eos/helmholtz/*.o
	rm -rf ./weakrates/*.o

