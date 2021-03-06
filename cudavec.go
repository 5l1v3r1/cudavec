// Package cudavec is an anyvec plugin for CUDA.
package cudavec

import (
	"errors"

	"github.com/unixpickle/cuda"
	"github.com/unixpickle/cuda/cublas"
	"github.com/unixpickle/cuda/curand"
	"github.com/unixpickle/essentials"
)

const maxCudaStreams = 32

// A Handle is the first thing you must obtain in order to
// use the package.
//
// It maintains various internal structures that Creators
// can use.
type Handle struct {
	context   *cuda.Context
	allocator cuda.Allocator

	gen  *curand.Generator
	blas *cublas.Handle

	kernels32 *cuda.Module

	streams []*cuda.Stream
}

// NewHandleDefault creates a handle with the default CUDA
// device and allocator.
func NewHandleDefault() (*Handle, error) {
	return NewHandle(nil, nil)
}

// NewHandle creates a Handle using the specified context
// and allocator.
//
// If the context is nil, a new one is created.
//
// If the allocator is nil, a new one is created.
func NewHandle(ctx *cuda.Context, all cuda.Allocator) (h *Handle, err error) {
	defer essentials.AddCtxTo("create Handle", &err)
	if ctx == nil {
		devs, err := cuda.AllDevices()
		if err != nil {
			return nil, err
		}
		if err != nil {
			return nil, errors.New("no CUDA devices")
		}
		ctx, err = cuda.NewContext(devs[0], -1)
		if err != nil {
			return nil, err
		}
	}

	h = &Handle{context: ctx, allocator: all}
	err = <-ctx.Run(func() (err error) {
		h.gen, err = curand.NewGenerator(ctx, curand.PseudoDefault)
		if err != nil {
			return err
		}
		err = h.gen.GenerateSeeds()
		if err != nil {
			return err
		}

		h.blas, err = cublas.NewHandle(ctx)
		if err != nil {
			return err
		}

		h.kernels32, err = cuda.NewModule(ctx, kernels32PTX)
		if err != nil {
			return err
		}

		if h.allocator == nil {
			h.allocator, err = cuda.BFCAllocator(ctx, 0)
			if err != nil {
				return err
			}
			h.allocator = cuda.GCAllocator(h.allocator, 0)
		}
		return nil
	})

	if err != nil {
		return nil, err
	}
	return h, nil
}
