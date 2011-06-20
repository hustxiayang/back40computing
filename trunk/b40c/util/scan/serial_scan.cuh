/******************************************************************************
 * 
 * Copyright 2010-2011 Duane Merrill
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 * For more information, see our Google Code project site: 
 * http://code.google.com/p/back40computing/
 * 
 * Thanks!
 * 
 ******************************************************************************/

/******************************************************************************
 * Serial scan over array types
 ******************************************************************************/

#pragma once

#include <b40c/util/operators.cuh>

namespace b40c {
namespace util {
namespace scan {

/**
 * Have each thread perform a serial scan over its specified segment.
 */
template <
	int NUM_ELEMENTS,				// Length of array segment to scan
	bool EXCLUSIVE = true>			// Whether or not this is an exclusive scan
struct SerialScan
{
	//---------------------------------------------------------------------
	// Iteration Structures
	//---------------------------------------------------------------------

	// Iterate
	template <int COUNT, int TOTAL>
	struct Iterate
	{
		template <typename T, typename ReductionOp>
		static __device__ __forceinline__ T Invoke(
			T partials[],
			T results[],
			T exclusive_partial,
			ReductionOp scan_op)
		{
			T inclusive_partial = scan_op(partials[COUNT], exclusive_partial);
			results[COUNT] = (EXCLUSIVE) ? exclusive_partial : inclusive_partial;
			return Iterate<COUNT + 1, TOTAL>::Invoke(
				partials, results, inclusive_partial, scan_op);
		}
	};

	// Terminate
	template <int TOTAL>
	struct Iterate<TOTAL, TOTAL>
	{
		template <typename T, typename ReductionOp>
		static __device__ __forceinline__ T Invoke(
			T partials[], T results[], T exclusive_partial, ReductionOp scan_op)
		{
			return exclusive_partial;
		}
	};

	//---------------------------------------------------------------------
	// Interface
	//---------------------------------------------------------------------

	/**
	 * Serial scan with the specified operator
	 */
	template <typename T, typename ReductionOp>
	static __device__ __forceinline__ T Invoke(
		T partials[],
		T exclusive_partial,			// Exclusive partial to seed with
		ReductionOp scan_op)
	{
		return Iterate<0, NUM_ELEMENTS>::Invoke(
			partials, partials, exclusive_partial, scan_op);
	}

	/**
	 * Serial scan with the addition operator
	 */
	template <typename T>
	static __device__ __forceinline__ T Invoke(
		T partials[],
		T exclusive_partial)			// Exclusive partial to seed with
	{
		return Invoke(partials, exclusive_partial, Operators<T>::Sum);
	}


	/**
	 * Serial scan with the specified operator
	 */
	template <typename T, typename ReductionOp>
	static __device__ __forceinline__ T Invoke(
		T partials[],
		T results[],
		T exclusive_partial,			// Exclusive partial to seed with
		ReductionOp scan_op)
	{
		return Iterate<0, NUM_ELEMENTS>::Invoke(
			partials, results, exclusive_partial, scan_op);
	}

	/**
	 * Serial scan with the addition operator
	 */
	template <typename T>
	static __device__ __forceinline__ T Invoke(
		T partials[],
		T results[],
		T exclusive_partial)			// Exclusive partial to seed with
	{
		return Invoke(partials, results, exclusive_partial, Operators<T>::Sum);
	}
};



} // namespace scan
} // namespace util
} // namespace b40c

