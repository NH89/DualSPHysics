#!/bin/bash

# "name" and "dirout" are named according to the testcase

name=CaseDambreak
dirout=${name}_out

# "executables" are renamed and called from their directory

dirbin=../../../bin/linux
gencase="${dirbin}/GenCase4_linux64"
dualsphysicscpu="${dirbin}/DualSPHysics4.2CPU_linux64"
dualsphysicsgpu="${dirbin}/DualSPHysics4.2_linux64"
boundaryvtk="${dirbin}/BoundaryVTK4_linux64"
partvtk="${dirbin}/PartVTK4_linux64"
partvtkout="${dirbin}/PartVTKOut4_linux64"
measuretool="${dirbin}/MeasureTool4_linux64"
computeforces="${dirbin}/ComputeForces4_linux64"
isosurface="${dirbin}/IsoSurface4_linux64"
measureboxes="${dirbin}/MeasureBoxes4_linux64"


# Library path must be indicated properly

current=$(pwd)
cd $dirbin
path_so=$(pwd)
cd $current
export LD_LIBRARY_PATH=$path_so


# "dirout" is created to store results or it is cleaned if it already exists

if [ -e $dirout ]; then
  rm -r $dirout
fi
mkdir $dirout
diroutdata=${dirout}/data; mkdir $diroutdata

# CODES are executed according the selected parameters of execution in this testcase
errcode=0

# Executes GenCase4 to create initial files for simulation.
if [ $errcode -eq 0 ]; then
  $gencase ${name}_Def $dirout/$name -save:all
  errcode=$?
fi

# Executes DualSPHysics to simulate SPH method.
if [ $errcode -eq 0 ]; then
  $dualsphysicscpu -cpu $dirout/$name $dirout -dirdataout data -svres -tmax:0.0005 -tout:0.0001
  errcode=$?
fi

# Executes PartVTK4 to create VTK files with particles.
dirout2=${dirout}/particles; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $partvtk -dirin $diroutdata -savevtk $dirout2/PartFluid -onlytype:-all,+fluid
  errcode=$?
fi

# Executes PartVTKOut4 to create VTK files with excluded particles.
if [ $errcode -eq 0 ]; then
  $partvtkout -dirin $diroutdata -filexml $dirout/${name}.xml -savevtk $dirout2/PartFluidOut -SaveResume $dirout/ResumeFluidOut
  errcode=$?
fi

# Executes MeasureTool4 to create VTK files with velocity and a CSV file with velocity at each simulation time.
dirout2=${dirout}/velocity; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $measuretool -dirin $diroutdata -points CaseDambreak_PointsVelocity.txt -onlytype:-all,+fluid -vars:-all,+vel.x,+vel.m -savevtk $dirout2/PointsVelocity -savecsv $dirout/PointsVelocity
  errcode=$?
fi

# Executes MeasureTool4 to create VTK files with incorrect pressure and a CSV file with value at each simulation time.
dirout2=${dirout}/pressure; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $measuretool -dirin $diroutdata -points CaseDambreak_PointsPressure_Incorrect.txt -onlytype:-all,+fluid -vars:-all,+press,+kcorr -kcusedummy:0 -kclimit:0.5 -savevtk $dirout2/PointsPressure_Incorrect -savecsv $dirout/PointsPressure_Incorrect
  errcode=$?
fi

# Executes MeasureTool4 to create VTK files with correct pressure and a CSV file with value at each simulation time.
if [ $errcode -eq 0 ]; then
  $measuretool -dirin $diroutdata -points CaseDambreak_PointsPressure_Correct.txt -onlytype:-all,+fluid -vars:-all,+press,+kcorr -kcusedummy:0 -kclimit:0.5 -savevtk $dirout2/PointsPressure_Correct -savecsv $dirout/PointsPressure_Correct
  errcode=$?
fi

# Executes ComputeForces to create a CSV file with force at each simulation time.
if [ $errcode -eq 0 ]; then
  $computeforces -dirin $diroutdata -filexml $dirout/${name}.xml -onlymk:21 -savecsv $dirout/WallForce
  errcode=$?
fi

# Executes IsoSurface4 to create VTK files with surface fluid and slices of surface.
dirout2=${dirout}/surface; mkdir $dirout2
planesy="-slicevec:0:0.1:0:0:1:0 -slicevec:0:0.2:0:0:1:0 -slicevec:0:0.3:0:0:1:0 -slicevec:0:0.4:0:0:1:0 -slicevec:0:0.5:0:0:1:0 -slicevec:0:0.6:0:0:1:0"
planesx="-slicevec:0.1:0:0:1:0:0 -slicevec:0.2:0:0:1:0:0 -slicevec:0.3:0:0:1:0:0 -slicevec:0.4:0:0:1:0:0 -slicevec:0.5:0:0:1:0:0 -slicevec:0.6:0:0:1:0:0 -slicevec:0.7:0:0:1:0:0 -slicevec:0.8:0:0:1:0:0 -slicevec:0.9:0:0:1:0:0 -slicevec:1.0:0:0:1:0:0"
planesd="-slice3pt:0:0:0:1:0.7:0:1:0.7:1"
if [ $errcode -eq 0 ]; then
  $isosurface -dirin $diroutdata -saveiso $dirout2/Surface vars:-all,vel,rhop,idp,type -saveslice $dirout2/Slices $planesy $planesx $planesd
  errcode=$?
fi

# Executes MeasureBoxes4 to create VTK files with particles assigned to different zones and a CSV file with information of each zone.
dirout2=${dirout}/meaboxes; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $measureboxes -dirin $diroutdata -fileboxes CaseDambreak_FileBoxes.txt -savecsv $dirout/ResultBoxes.csv -savevtk $dirout2/Boxes.vtk
  errcode=$?
fi



if [ $errcode -eq 0 ]; then
  echo All done
else
  echo Execution aborted
fi
read -n1 -r -p "Press any key to continue..." key
echo
